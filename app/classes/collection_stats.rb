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
=end
