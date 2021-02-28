# frozen_string_literal: true

require 'rails_helper'

describe CollectionStats do
  let(:collection) { Collection.new(id: 'agency_blogs', token: 'token') }
  let(:collection_stats) { CollectionStats.new(collection) }
 
  describe 'initialization' do
    it 'requires a collection' do
      expect { CollectionStats.new }.to raise_error ArgumentError
    end
  end

  describe '#document_total' do
    subject(:document_total) { collection_stats.document_total }

    describe 'by default' do
      it { is_expected.to eq 0 }
    end
  end
end
