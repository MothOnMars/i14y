# frozen_string_literal: true

class CollectionRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  extend NamespacedIndex

  klass Collection
  client DEFAULT_CLIENT
  index_name index_namespace
end
