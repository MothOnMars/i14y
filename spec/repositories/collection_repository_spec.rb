# frozen_string_literal: true

require 'rails_helper'

describe CollectionRepository do
  subject(:repository) { described_class.new }

  it 'stores collections' do
    expect(repository.klass).to eq(Collection)
  end

  it 'uses the collections index alias' do
    expect(repository.index_name).to eq('test-i14y-collections')
  end

  it 'can connect to Elasticsearch' do
    expect(repository.client.ping).to be(true)
  end

  describe 'serialization' do
    subject(:serialized_collection) { repository.serialize(collection) }

    context 'when the collection is new' do
      let(:collection) { Collection.new(id: 'foo', token: 'bar') }

      it 'populates the timestamp fields' do
        expect(serialized_collection[:created_at]).to be_a(Time)
        expect(serialized_collection[:updated_at]).to be_a(Time)
      end
    end
  end
end
