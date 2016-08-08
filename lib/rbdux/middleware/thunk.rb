module Rbdux
  module Middleware
    class Thunk
      def before(store, action)
        func = action.class.dispatch_func

        return nil unless func

        func.call(store, action)
      end
    end
  end
end
