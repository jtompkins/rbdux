require 'rbdux/stores/immutable_memory_store'
require 'hamster'

describe Rbdux::Stores::ImmutableMemoryStore do
  let(:initial_state) do
    {
      a_key: 'a_value',
      another_key: 'another_value'
    }
  end

  let(:end_state) do
    {
      a_key: 'a_new_value',
      another_key: 'another_value'
    }
  end

  let(:a_different_state) do
    {
      one_more_key: 'one_more_value'
    }
  end

  let(:store) do
    Rbdux::Stores::ImmutableMemoryStore.with_state(initial_state)
  end

  describe '.with_state' do
    it 'builds a MemoryStore with the specified state' do
      s = Rbdux::Stores::ImmutableMemoryStore.with_state(initial_state)

      expect(s.all).to eq(initial_state)
    end

    it 'converts a Hash to a Hamster::Hash' do
      s = Rbdux::Stores::ImmutableMemoryStore.with_state(initial_state)

      expect(s.instance_variable_get(:@state)).to be_a Hamster::Hash
    end
  end

  describe '#fetch' do
    it 'returns part of the tree by key' do
      expect(store.fetch(:a_key)).to eq('a_value')
    end

    context 'when a default argument is given' do
      it 'returns the default if the key isn\'t found' do
        expect(store.fetch(:not_found, [])).to eq([])
      end
    end

    context 'when a block is given' do
      it 'calls the block if the key isn\'t found' do
        called = false

        store.fetch(:not_found) { called = true }

        expect(called).to be_truthy
      end
    end
  end

  describe '#all' do
    it 'returns the entire state tree' do
      expect(store.all).to eq(initial_state)
    end

    it 'converts the internal immutable hash to a normal Hash' do
      expect(store.all).to be_a Hash
    end
  end

  describe '#set' do
    it 'sets a single value by key' do
      store.set(:a_key, 'a_new_value')

      expect(store.all).to eq(end_state)
    end
  end

  describe '#replace' do
    it 'replaces the entire state tree' do
      store.replace(a_different_state)

      expect(store.all).to eq(a_different_state)
    end
  end
end
