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

      expect(s.get_all).to eq(initial_state)
    end

    it 'converts a Hash to a Hamster::Hash' do
      s = Rbdux::Stores::ImmutableMemoryStore.with_state(initial_state)

      expect(s.instance_variable_get(:@state)).to be_a Hamster::Hash
    end
  end

  describe '#get' do
    it 'returns part of the tree by key' do
      expect(store.get(:a_key)).to eq('a_value')
    end
  end

  describe '#get_all' do
    it 'returns the entire state tree' do
      expect(store.get_all).to eq(initial_state)
    end

    it 'converts the internal immutable hash to a normal Hash' do
      expect(store.get_all).to be_a Hash
    end
  end

  describe '#set' do
    it 'sets a single value by key' do
      store.set(:a_key, 'a_new_value')

      expect(store.get_all).to eq(end_state)
    end
  end

  describe '#replace' do
    it 'replaces the entire state tree' do
      store.replace(a_different_state)

      expect(store.get_all).to eq(a_different_state)
    end
  end
end
