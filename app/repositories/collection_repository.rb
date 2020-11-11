class CollectionRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  extend NamespacedIndex

  klass Collection
 client DEFAULT_CLIENT

 #index_name Collection.index_namespace # FIXME

  settings index: { number_of_shards: 1 }

end

