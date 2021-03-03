# frozen_string_literal: true

class DocumentRepository
  include Repository

  klass Document

  def serialize(document)
    document_hash = ActiveSupport::HashWithIndifferentAccess.new(super)
    Serde.serialize_hash(document_hash, document_hash[:language])
  end

  def deserialize(hash)
    doc_hash = source_hash(hash)
    deserialized_hash = Serde.deserialize_hash(doc_hash,
                                               doc_hash['language'])
    klass.new deserialized_hash
  end

  def es6_count
    # This method exists to ensure compatibility with both ES 6 and 7.
    # Once we no longer need support for ES 6, this can be replaced by the
    # standard DocumentRepository#count method.
    count
  end
end
