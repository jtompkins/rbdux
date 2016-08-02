module Rbdux
  class Action
    class << self
      def define(type_name, &block)
        klass_name = "#{prepare_action_name(type_name)}Action"

        return Object.const_get(klass_name) if Object.const_defined? klass_name

        Object.const_set(klass_name, build_action_type(block))
      end

      private

      class BaseAction
        class << self
          attr_reader :dispatch_func

          def empty
            new(nil, nil)
          end

          def with_payload(payload)
            new(payload, nil)
          end

          def with_error(error)
            new(nil, error)
          end
        end

        attr_reader :payload, :error

        def error?
          !error.nil?
        end

        private

        def initialize(payload, error)
          @payload = payload
          @error = error
        end
      end

      def prepare_action_name(name)
        camelize_action_name(name.tr('-', '_')).gsub('Action', '')
      end

      def camelize_action_name(name)
        name.split('_').collect { |n| capitalize(n) }.join
      end

      def capitalize(name)
        name_array = name.split('')
        name_array.first.upcase!
        name_array.join
      end

      def build_action_type(func)
        Class.new(BaseAction) do
          @dispatch_func = func
        end
      end
    end
  end
end
