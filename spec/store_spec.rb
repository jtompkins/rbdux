require 'rbdux'

describe Rbdux::Store do
  before do
    Rbdux::Store.reset
    Rbdux::Store.with_store(Rbdux::Stores::MemoryStore.with_state({}))
  end

  it 'delegates all calls to the singleton instance' do
    expect_any_instance_of(Rbdux::Store).to receive(:get).with('a_key')

    Rbdux::Store.get('a_key')
  end

  describe '.reset' do
    it 'removes the existing singleton value and recreates it' do
      old_instance = Rbdux::Store.instance

      Rbdux::Store.reset

      expect(old_instance).to_not eq(Rbdux::Store.instance)
    end
  end

  describe '#with_store' do
    it 'raises an error if a container is not passed in' do
      expect { Rbdux::Store.with_store }.to raise_error(ArgumentError)
    end
  end

  describe '#before' do
    it 'raises an error if a block is not passed in' do
      expect { Rbdux::Store.before }.to raise_error(ArgumentError)
    end

    it 'returns the Store instance' do
      store = Rbdux::Store.before(&-> { true })

      expect(store).to eq(Rbdux::Store.instance)
    end
  end

  describe '#after' do
    it 'raises an error if a block is not passed in' do
      expect { Rbdux::Store.after }.to raise_error(ArgumentError)
    end

    it 'returns the Store instance' do
      store = Rbdux::Store.after(&-> { true })

      expect(store).to eq(Rbdux::Store.instance)
    end
  end

  describe '#get' do
    let(:expected_state) do
      {
        a_key: 'a_value'
      }
    end

    let(:memory_store) do
      Rbdux::Stores::MemoryStore.with_state(expected_state)
    end

    context 'when no key is given' do
      it 'returns the entire state of the store' do
        Rbdux::Store.with_store(memory_store)

        expect(Rbdux::Store.get).to eq(expected_state)
      end
    end

    context 'when a key is given' do
      it 'returns only a slice of the state' do
        Rbdux::Store.with_store(memory_store)

        expect(Rbdux::Store.get(:a_key)).to eq('a_value')
      end
    end
  end

  describe '#reduce' do
    it 'raises an error if a block is not passed in' do
      expect { Rbdux::Store.reduce }.to raise_error(ArgumentError)
    end

    it 'returns the Store instance' do
      Rbdux::Action.define('add_todo')

      store = Rbdux::Store.reduce(AddTodoAction, &-> { true })

      expect(store).to eq(Rbdux::Store.instance)
    end
  end

  describe '#dispatch' do
    before do
      Rbdux::Action.define('add_todo')
      Rbdux::Action.define('complete_todo')
      Rbdux::Store.with_store(memory_store)
    end

    let(:initial_state) do
      {
        can_add_todos: false,
        todos: [
          { id: 1, text: 'First todo', finished: false },
          { id: 2, text: 'Second todo', finished: false }
        ]
      }
    end

    let(:memory_store) do
      Rbdux::Stores::MemoryStore.with_state(initial_state)
    end

    let(:add_reducer) { -> (_, _) { true } }
    let(:complete_reducer) { -> (_, _) { 'complete callback' } }

    let(:add_action) { AddTodoAction.with_payload(text: 'Third todo') }
    let(:complete_action) { CompleteTodoAction.with_payload(id: 1) }

    it 'calls the reducers with the action payload' do
      expect(add_reducer).to receive(:call).with(initial_state, add_action)

      Rbdux::Store.reduce(AddTodoAction, &add_reducer)
      Rbdux::Store.dispatch(add_action)
    end

    it 'calls the appropriate reducers based on the action type' do
      expect(add_reducer).to receive(:call).with(initial_state, add_action)
      expect(complete_action).to_not receive(:call)

      Rbdux::Store.reduce(AddTodoAction, &add_reducer)
      Rbdux::Store.reduce(CompleteTodoAction, &complete_reducer)
      Rbdux::Store.dispatch(add_action)
    end

    it 'notifies the subscribers after the reducers run' do
      subscribe_cb = -> { 'a subscription callback' }

      expect(subscribe_cb).to receive(:call)

      Rbdux::Store.subscribe(&subscribe_cb)
      Rbdux::Store.dispatch(add_action)
    end

    context 'when no store key is provided to the reducer' do
      it 'passes the entire state to the reducer' do
        expect(add_reducer).to receive(:call).with(initial_state, add_action)

        Rbdux::Store.reduce(AddTodoAction, &add_reducer)
        Rbdux::Store.dispatch(add_action)
      end

      it 'replaces the state with whatever is reduced by the reducer' do
        Rbdux::Store.reduce(AddTodoAction, &add_reducer)
        Rbdux::Store.dispatch(add_action)

        expect(Rbdux::Store.get).to eq(true)
      end
    end

    context 'when a store key is provided to the reducer' do
      let(:final_state) do
        {
          can_add_todos: true,
          todos: [
            { id: 1, text: 'First todo', finished: false },
            { id: 2, text: 'Second todo', finished: false }
          ]
        }
      end

      it 'passes a subset of the store to the reducer' do
        expect(add_reducer).to receive(:call).with(false, add_action)

        Rbdux::Store.reduce(AddTodoAction, :can_add_todos, &add_reducer)
        Rbdux::Store.dispatch(add_action)
      end

      it 'merges the return values from the reducers into the state' do
        Rbdux::Store.reduce(AddTodoAction, :can_add_todos, &add_reducer)
        Rbdux::Store.dispatch(add_action)

        expect(Rbdux::Store.get).to eq(final_state)
      end
    end

    context 'when middleware is added' do
      let(:modified_action) do
        AddTodoAction.with_payload(modified_key: 'a modified key')
      end

      let(:before_ware) { -> (_, _) { modified_action } }
      let(:another_before) { -> (_, _) { nil } }
      let(:after_ware) { -> (_, _, _) {} }
      let(:middleware_reducer) { -> (_, _) {} }

      before do
        Rbdux::Store.before(&before_ware)
        Rbdux::Store.before(&another_before)
        Rbdux::Store.after(&after_ware)
      end

      it 'calls the before middlware before calling the reducers' do
        expect(before_ware)
          .to receive(:call)
          .with(Rbdux::Store.instance, add_action)

        Rbdux::Store.dispatch(add_action)
      end

      it 'passes the result of each middleware as the action to the next' do
        expect(another_before)
          .to receive(:call)
          .with(Rbdux::Store.instance, modified_action)

        Rbdux::Store.dispatch(add_action)
      end

      it 'does not update the action if the middleware returns nil' do
        expect(middleware_reducer)
          .to receive(:call)
          .with(Rbdux::Store.get, modified_action)

        Rbdux::Store.reduce(AddTodoAction, &middleware_reducer)
        Rbdux::Store.dispatch(add_action)
      end

      it 'calls the after middleware after calling the reducers' do
        expect(after_ware)
          .to receive(:call)
          .with(initial_state, initial_state, modified_action)

        Rbdux::Store.dispatch(add_action)
      end
    end
  end

  describe '#subscribe' do
    let(:subscription_lambda) { -> { 'a lambda' } }

    it 'returns an ID that can be used to unsubscribe' do
      expect(Rbdux::Store.subscribe(&subscription_lambda)).to be_a String
    end

    it 'raises an error if a block is not passed in' do
      expect { Rbdux::Store.subscribe }.to raise_error(StandardError)
    end
  end

  describe '#unsubscribe' do
    let(:subscription_lambda) { -> { 'a lambda' } }

    it 'does not notify an unsubscribed object' do
      guid = Rbdux::Store.subscribe(&subscription_lambda)

      expect(subscription_lambda).to_not receive(:call)

      Rbdux::Store.unsubscribe(guid)

      Rbdux::Store.dispatch({})
    end
  end
end
