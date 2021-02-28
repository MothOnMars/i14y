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

    context 'when documents are associated with the collection' do
      let(:index_name) { DocumentRepository.index_namespace('agency_blogs') }
      let(:document_repository) do
        DocumentRepository.new(index_name: index_name)
      end
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

      it 'returns the number of documents' do
        expect(document_total).to eq 2
      end
    end
  end
end
