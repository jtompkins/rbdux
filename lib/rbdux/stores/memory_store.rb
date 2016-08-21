require 'thread'

module Rbdux
  module Stores
    class MemoryStore
      def self.with_state(state)
        MemoryStore.new(state)
      end

      def fetch(key, default_value = nil)
        if block_given?
          state.fetch(key) { yield }
        else
          state.fetch(key, default_value)
        end
      end

      def all
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
