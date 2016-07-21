require 'action'

describe Rbdux::Action do
  describe '.define' do
    let(:action) { Rbdux::Action.define(action_type) }
    let(:action_type) { 'test' }
    let(:action_name) { action.name.split('::').last }

    context 'when the action type is already defined' do
      it 'does not re-define the action' do
        expect do
          Rbdux::Action.define('duplicate_test')
          Rbdux::Action.define('duplicate_test')
        end.to_not output.to_stderr
      end
    end

    context 'when given a name that starts with a capital letter' do
      let(:normal_name) { 'TestAction' }

      it 'does not change the name' do
        expect(Rbdux::Action.define(normal_name).name).to eq normal_name
      end
    end

    context 'when given a name that starts with a lowercase letter' do
      let(:lowercase_name) { 'testAction' }
      let(:lowercase_class_name) { 'TestAction' }

      it 'applies capitalizes the first letter but preserves the rest' do
        expect(Rbdux::Action.define(lowercase_name).name)
          .to eq(lowercase_class_name)
      end
    end

    context 'when given a name with underscores' do
      let(:underscores_action) { 'test_with_underscores' }
      let(:underscores_class_name) { 'TestWithUnderscoresAction' }

      it 'Removes the dashes and applies pascal casing' do
        expect(Rbdux::Action.define(underscores_action).name)
          .to eq(underscores_class_name)
      end
    end

    context 'when given a name with dashes' do
      let(:dashes_action) { 'test-with-dashes' }
      let(:dashes_class_name) { 'TestWithDashesAction' }

      it 'removes the dashes and applies pascal casing' do
        expect(Rbdux::Action.define(dashes_action).name)
          .to eq(dashes_class_name)
      end
    end

    context 'when given a name that contains "Action"' do
      let(:action_action) { 'ActionNameTestAction' }
      let(:action_action_class_name) { 'NameTestAction' }

      it 'removes the "Action" from the name' do
        expect(Rbdux::Action.define(action_action).name)
          .to eq(action_action_class_name)
      end
    end

    context 'when passed a block parameter' do
      let(:action_func) { -> (_, _) { true } }
      let(:action_with_func) do
        Rbdux::Action.define('action_with_func', &action_func)
      end

      it 'sets the action type\'s #func to the block' do
        expect(action_with_func.instance_variable_get(:@dispatch_func))
          .to eq(action_func)
      end
    end

    it 'defines a new class with the given action type name' do
      expect(action).to be_a(Class)
    end

    it 'appends "Action" to the class name' do
      expect(action_name.end_with?('Action')).to be_truthy
    end

    it 'captializes the class name' do
      expect(action_name.start_with?('Test')).to be_truthy
    end

    it 'adds a .empty static method to the new class' do
      expect(action.method(:empty)).not_to be_nil
    end

    it 'adds a .with_payload static method to the new class' do
      expect(action.method(:with_payload)).not_to be_nil
    end

    it 'adds a .with_error static method to the new class' do
      expect(action.method(:with_error)).not_to be_nil
    end

    it 'adds a .dispatch_func static reader to the new class' do
      expect(action.method(:dispatch_func)).not_to be_nil
    end
  end

  context 'in the created class' do
    let(:action) { Rbdux::Action.define('test') }

    describe '.with_payload' do
      subject(:action_instance) { action.with_payload(payload) }
      let(:payload) do
        { test: 'a test' }
      end

      it 'builds a new instance of the Action type' do
        expect(action_instance).to be_a(TestAction)
      end

      it 'sets the #payload to contain the passed-in payload' do
        expect(action_instance.payload).to eq(payload)
      end

      it 'sets the #error? to false' do
        expect(action_instance.error?).to be_falsey
      end
    end

    describe '.with_error' do
      subject(:action_instance) { action.with_error(error) }
      let(:error) { StandardError.new('a test error') }

      it 'builds a new instance of the Action type' do
        expect(action_instance).to be_a(TestAction)
      end

      it 'sets the #error to contain the passed-in error' do
        expect(action_instance.error).to eq(error)
      end

      it 'sets the #error? to true' do
        expect(action_instance).to be_truthy
      end
    end
  end
end
