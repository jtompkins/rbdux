require 'hamster'

module Rbdux
  module Stores
    class ImmutableMemoryStore
      def self.with_state(state)
        ImmutableMemoryStore.new(state)
      end

      def get(key)
        state[key]
      end

      def get_all
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
