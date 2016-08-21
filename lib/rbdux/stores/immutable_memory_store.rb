require 'hamster'

module Rbdux
  module Stores
    class ImmutableMemoryStore
      def self.with_state(state)
        ImmutableMemoryStore.new(state)
      end

      def fetch(key, default_value = nil)
        if block_given?
          state.fetch(key) { yield }
        else
          state.fetch(key, default_value)
        end
      end

      def all
        state.to_h
      end

      def set(key, value)
        @state = state.put(key, value)
      end

      def replace(state)
        @state = Hamster::Hash.new(state)
      end

      private

      attr_reader :state

      def initialize(state)
        @state = Hamster::Hash.new(state)
      end
    end
  end
end
