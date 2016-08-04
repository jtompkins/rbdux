require 'securerandom'

module Rbdux
  class Store
    class << self
      @instance = nil

      def instance
        @instance ||= Store.new
      end

      def reset
        @instance = nil
      end

      def with_state(state)
        @instance = Store.new(state)
      end

      def method_missing(method, *args, &block)
        return unless instance.respond_to?(method)

        @instance.send(method, *args, &block)
      end
    end

    attr_reader :state

    def when_merging(&block)
      validate_functional_inputs(block)

      @merge_func = block

      self
    end

    def when_getting(&block)
      validate_functional_inputs(block)

      @get_func = block

      self
    end

    def before(&block)
      validate_functional_inputs(block)

      @before_middleware << block

      self
    end

    def after(&block)
      validate_functional_inputs(block)

      @after_middleware << block

      self
    end

    def reduce(action, state_key = nil, &block)
      validate_functional_inputs(block)

      key = action.name

      reducers[key] = [] unless reducers.key?(key)
      reducers[key] << Reducer.new(state_key, block)

      self
    end

    def dispatch(action)
      previous_state = state

      dispatched_action = apply_before_middleware(action)

      reducers.fetch(action.class.name, []).each do |reducer|
        apply_reducer!(reducer, dispatched_action)
      end

      apply_after_middleware(previous_state, dispatched_action)

      observers.values.each(&:call)
    end

    def subscribe(&block)
      validate_functional_inputs(block)

      subscriber_id = SecureRandom.uuid

      observers[subscriber_id] = block

      subscriber_id
    end

    def unsubscribe(subscriber_id)
      observers.delete(subscriber_id)
    end

    private

    Reducer = Struct.new(:state_key, :func)

    attr_reader :observers, :reducers

    def initialize(state = {})
      @state = state
      @observers = {}
      @reducers = {}
      @before_middleware = []
      @after_middleware = []
      @merge_func = nil
    end

    def apply_before_middleware(action)
      dispatched_action = action

      @before_middleware.each do |m|
        new_action = m.call(self, dispatched_action)
        dispatched_action = new_action unless new_action.nil?
      end

      dispatched_action
    end

    def apply_after_middleware(previous_state, action)
      @after_middleware.each do |m|
        m.call(previous_state, state, action)
      end
    end

    def apply_reducer!(reducer, action)
      new_state = reducer.func.call(slice_state(reducer.state_key), action)

      return if new_state.nil?

      @state =  merge_state(new_state, reducer.state_key)
    end

    def slice_state(state_key)
      return state unless state_key

      state[state_key]
    end

    def merge_state(new_state, state_key)
      if @merge_func.nil?
        default_merge(state, new_state, state_key)
      else
        @merge_func.call(state, new_state, state_key)
      end
    end

    def default_merge(old_state, new_state, state_key)
      old_state.dup.merge(state_key ? { state_key => new_state } : new_state)
    end

    def validate_functional_inputs(block)
      raise ArgumentError, 'You must define a block.' unless block
    end
  end
end
