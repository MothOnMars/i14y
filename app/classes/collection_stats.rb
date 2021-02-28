# frozen_string_literal: true

class CollectionStats
  attr_reader :collection

  def initialize(collection)
    @collection = collection
  end

  def document_total
    DocumentRepository.new(
      index_name: DocumentRepository.index_namespace(collection.id)
    ).count
  end

  def last_document_sent
    document_repository =     DocumentRepository.new(
      index_name: DocumentRepository.index_namespace(collection.id)
    )
    document_repository.search(size:1, sort: { updated_at: "desc"}).
      results.first.updated_at.utc.to_s
  end
end

=begin
  def document_total
    document_repository.count
  end

  def last_document_sent
    document_repository.search("*:*", {size:1, sort: "updated_at:desc"}).
      results.first.updated_at.utc.to_s
  rescue
    nil
  end

  private

  def document_repository
    @document_repository = DocumentRepository.new(
      index_name: DocumentRepository.index_namespace(id)
    )
  end

  index: documents_index_name,
spec/requests/api/v1/documents_spec.rb-          id: id,
spec/requests/api/v1/documents_spec.rb-          body: {
spec/requests/api/v1/documents_spec.rb-            doc: {
spec/requests/api/v1/documents_spec.rb-              updated_at: 1.year.ago,
spec/requests/api/v1/documents_spec.rb-              created_at: 1.year.ago
Binary file vendor/stream2es matches

    client.bulk body: [
      { index: { _index: 'myindex', _type: 'mytype', _id: 1 } },
      { title: 'foo' },

      { index: { _index: 'myindex', _type: 'mytype', _id: 2 } },
      { title: 'foo' },

      { delete: { _index: 'myindex', _type: 'mytype', _id: 3  } }
    ]


      describe '#last_document_sent' do
    subject(:last_document_sent) { collection.last_document_sent }

    context 'when something goes wrong' do
      before do
        allow_any_instance_of(DocumentRepository).
          to receive(:search).and_raise(StandardError)
      end

      it { is_expected.to be nil }
    end
=end
