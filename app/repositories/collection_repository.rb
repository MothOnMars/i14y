# frozen_string_literal: true

class CollectionRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  extend NamespacedIndex

  klass Collection
  client ES.client
  index_name index_namespace

  def serialize(collection)
    collection.created_at = Time.now.utc #unless collection.persisted?
    collection.to_hash
  end
end
