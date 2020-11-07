class CollectionRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  extend NamespacedIndex

  klass Collection

  index_name index_namespace

  settings index: { number_of_shards: 1 }

end

