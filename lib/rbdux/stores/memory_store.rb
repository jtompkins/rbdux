require 'thread'

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
        @lock.synchronize do
          state[key] = value
        end
      end

      def replace(state)
        @lock.synchronize do
          @state = state
        end
      end

      private

      attr_reader :state

      def initialize(state)
        @state = state
        @lock = Mutex.new
      end
    end
  end
end
