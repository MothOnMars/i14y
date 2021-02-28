# frozen_string_literal: true

require 'rails_helper'

describe CollectionStats do
  let(:collection) { Collection.new(id: 'agency_blogs', token: 'token') }
  let(:index_name) { DocumentRepository.index_namespace('agency_blogs') }
  let(:document_repository) { DocumentRepository.new(index_name: index_name) }
  let(:collection_stats) { CollectionStats.new(collection) }

  shared_context 'when documents are associated with the collection' do
    let(:document1_params) do
      {
        path: 'https://agency.gov/1.html',
        language: 'en'
      }
    end
    let(:document2_params) do
      {
        path: 'https://agency.gov/1.html',
        language: 'en'
      }
    end

    before do
      create_document(document1_params, document_repository)
      create_document(document2_params, document_repository)
    end
  end

  before do
    # FIXME: do this more efficiently
    ES.client.indices.delete(index: index_name, ignore_unavailable: true)
    document_repository.create_index!
  end

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

    context 'when documents are associated with the collection' do
      include_context 'when documents are associated with the collection'

      it 'returns the number of documents' do
        expect(document_total).to eq 2
      end
    end
  end

  describe '#last_document_sent' do
    subject(:last_document_sent) { collection_stats.last_document_sent }

    describe 'by default' do
      it { is_expected.to be nil }
    end
  end
end
