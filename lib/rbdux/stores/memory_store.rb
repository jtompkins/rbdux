module Rbdux
  module Stores
    class MemoryStore
      def self.with_state(state)
        MemoryStore.new(state)
      end

      def get(key)
        state[key]
      end

      def get_all
        state
      end

      def set(key, value)
        state[key] = value
      end

      def replace(state)
        @state = state
      end

      private

      attr_reader :state

      def initialize(state)
        @state = state
      end
    end
  end
end
