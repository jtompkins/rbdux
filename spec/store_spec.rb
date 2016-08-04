require 'rbdux'

describe Rbdux::Store do
  before do
    Rbdux::Store.reset
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

  describe '.with_initial_state' do
    let(:expected_state) do
      {
        a_key: 'a_value'
      }
    end

    it 'sets the Rbdux::Store\'s initial state' do
      Rbdux::Store.with_state(expected_state)

      expect(Rbdux::Store.state).to eq(expected_state)
    end

    it 'returns the Store instance' do
      expect(Rbdux::Store.with_state(expected_state))
        .to eq Rbdux::Store.instance
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

  describe '#when_getting' do
    it 'raises an error if a block is not passed in' do
      expect { Rbdux::Store.when_getting }.to raise_error(ArgumentError)
    end

    it 'returns the Store instance' do
      store = Rbdux::Store.when_getting(&-> { true })

      expect(store).to eq(Rbdux::Store.instance)
    end
  end

  describe '#when_merging' do
    it 'raises an error if a block is not passed in' do
      expect { Rbdux::Store.when_merging }.to raise_error(ArgumentError)
    end

    it 'returns the Store instance' do
      Rbdux::Action.define('add_todo')

      store = Rbdux::Store.when_merging(&-> { true })

      expect(store).to eq(Rbdux::Store.instance)
    end
  end

  describe '#get' do
    let(:expected_state) do
      {
        a_key: 'a_value'
      }
    end

    context 'when the get_func is set' do
      it 'calls the get_func instead of the default #get' do
      end
    end

    context 'when no key is given' do
      it 'returns the entire state of the store' do
        Rbdux::Store.with_state(expected_state)

        expect(Rbdux::Store.get).to eq(expected_state)
      end
    end

    context 'when a key is given' do
      it 'returns only a slice of the state' do
        Rbdux::Store.with_state(expected_state)

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
      Rbdux::Store.with_state(initial_state)
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

    let(:final_state) do
      {
        can_add_todos: true,
        todos: [
          { id: 1, text: 'First todo', finished: false },
          { id: 2, text: 'Second todo', finished: false }
        ]
      }
    end

    let(:sliced_value) { false }
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

    it 'slices the store if a slice is requested' do
      expect(add_reducer).to receive(:call).with(sliced_value, add_action)

      Rbdux::Store.reduce(AddTodoAction, :can_add_todos, &add_reducer)
      Rbdux::Store.dispatch(add_action)
    end

    it 'merges the return values from the sliced reducers' do
      Rbdux::Store.reduce(AddTodoAction, :can_add_todos, &add_reducer)
      Rbdux::Store.dispatch(add_action)

      expect(Rbdux::Store.state).to eq(final_state)
    end

    it 'notifies the subscribers after the reducers run' do
      subscribe_cb = -> { 'a subscription callback' }

      expect(subscribe_cb).to receive(:call)

      Rbdux::Store.subscribe(&subscribe_cb)
      Rbdux::Store.dispatch(add_action)
    end

    context 'when the store has a custom merge func defined' do
      let(:merge_output) do
        { custom_merge_func: true }
      end

      let(:merge_func) do
        lambda do |_, _, _|
          merge_output
        end
      end

      before do
        Rbdux::Store
          .when_merging(&merge_func)
          .reduce(AddTodoAction, :can_add_todos, &add_reducer)
      end

      it 'calls the user-defined merge func to handle merges' do
        expect(merge_func)
          .to receive(:call)
          .with(initial_state, true, :can_add_todos)

        Rbdux::Store.dispatch(add_action)
      end

      it 'does not call the default merge method' do
        expect(Rbdux::Store.instance).to_not receive(:default_merge)

        Rbdux::Store.dispatch(add_action)
      end

      it 'replaces the state with the value returned from the func' do
        Rbdux::Store.dispatch(add_action)

        expect(Rbdux::Store.state).to eq(merge_output)
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
          .with(Rbdux::Store.state, modified_action)

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
