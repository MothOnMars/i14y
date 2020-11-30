# frozen_string_literal: true

require 'rails_helper'

describe CollectionRepository do
  subject(:repository) { described_class.new }
  let(:klass_instance) do
    Collection.new(
      id: 'agency_blogs',
      token: 'secret'
    )
  end

  it_behaves_like 'a repository'

  it 'stores collections' do
    expect(repository.klass).to eq(Collection)
  end

  it 'uses the collections index alias' do
    expect(repository.index_name).to eq('test-i14y-collections')
  end

  describe 'serialization' do
    subject(:serialized_collection) { repository.serialize(collection) }

    context 'when the collection is new' do
      let(:collection) { Collection.new(id: 'foo', token: 'bar') }

      it 'populates the timestamp fields' do
        expect(serialized_collection[:created_at]).to be_a(Time)
        #expect(serialized_collection[:updated_at]).to be_a(Time)
      end
    end

    context 'when the collection is pre-existing' do
      let(:collection) do
        Collection.new(
          id: 'foo',
          token: 'bar',
          created_at: '2020-11-23 19:59:55 UTC',
          updated_at: '2020-11-23 19:59:55 UTC'
        )
      end

      it 'updates updated_at' do
      end
    end
  end
end
