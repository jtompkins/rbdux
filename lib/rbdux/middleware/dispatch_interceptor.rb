module Rbdux
  module Middleware
    module_function

    def dispatch_interceptor(store, action)
      func = action.class.dispatch_func

      return nil unless func

      func.call(store, action)
    end
  end
end
