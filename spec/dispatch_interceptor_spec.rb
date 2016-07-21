require 'action'
require 'store'
require 'middleware/dispatch_interceptor'

describe Rbdux::Middleware do
  describe '#dispatch_interceptor' do
    let(:func) { -> (_, action) { action } }
    let(:func_action) { Rbdux::Action.define('func_action', &func) }
    let(:no_func_action) { Rbdux::Action.define('no_func_action') }

    context 'when the Action class doesn\'t have a func defined' do
      it 'returns nil' do
        expect(Rbdux::Middleware
          .dispatch_interceptor(nil, no_func_action.empty))
          .to be_nil
      end
    end

    context 'when the Action class has a func defined' do
      let(:func_action_instance) { func_action.empty }

      it 'executes the Action class\' func' do
        expect(func).to receive(:call).with(nil, func_action_instance)

        Rbdux::Middleware.dispatch_interceptor(nil, func_action_instance)
      end

      it 'returns the original action' do
        expect(Rbdux::Middleware
          .dispatch_interceptor(nil, func_action_instance))
          .to eq(func_action_instance)
      end
    end
  end
end
