# frozen_string_literal: true

require 'rails_helper'

describe DocumentRepository do
  subject(:repository) { described_class.new }

  it_behaves_like 'a repository'

  describe '.klass' do
    subject(:klass) { described_class.klass }

    it { is_expected.to eq(Document) }
  end

  describe '.index_namespace' do
    subject(:index_namespace) { described_class.index_namespace('agency_blogs') }

    it 'returns the ES index namespace for the specified collection handle' do
      expect(index_namespace).to eq 'test-i14y-documents-agency_blogs'
    end
  end

  describe '#serialize' do
    subject(:serialize) { repository.serialize(document) }

    let(:document) do
      Document.new(
        language: 'en',
        path: 'http://www.agency.gov/page1.html'
      )
    end

    it 'serializes the document' do
      expect(serialize).to match(hash_including(
        language: 'en',
        path: 'http://www.agency.gov/page1.html'
      ))
    end
  end

  describe 'deserialization' do
    context 'when a document has been persisted' do
      let(:document_params) do
        {
          id: 'a123',
          language: 'en',
          path: 'http://www.agency.gov/page1.html',
          title: 'My Title',
          created: DateTime.new(2020, 1, 1),
          changed: DateTime.new(2020, 1, 2),
          description: 'My Description',
          content: 'some content',
          promote: true,
          tags: 'this,that',
          click_count: 5
        }
      end

      before do
        repository.create_index!
        create_document(document_params, repository)
      end

      after { repository.delete_index! }

      it 'deserializes the document' do
        document = repository.find('a123')
        expect(document.id).to eq('a123')
        expect(document.language).to eq('en')
        expect(document.path).to eq('http://www.agency.gov/page1.html')
        expect(document.title).to eq('My Title')
        expect(document.description).to eq('My Description')
        expect(document.content).to eq('some content')
        expect(document.promote).to eq(true)
        expect(document.tags).to eq(%w[this that])
        expect(document.click_count).to eq(5)
      end
    end
  end

  describe 'es6_count' do
    subject(:es6_count) { repository.es6_count }

    context 'when the index exists' do
      before { repository.create_index! }

      after { repository.delete_index! }

      it { is_expected.to eq 0 }

      context 'when the index contains documents' do
        before { repository.save({ foo: 'bar' }, refresh: true) }

        it 'returns the number of documents in the index' do
          expect(es6_count).to eq 1
        end
      end
    end
  end
end
