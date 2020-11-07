class DocumentRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  extend NamespacedIndex

  klass Document

  index_name index_namespace

  settings index: { number_of_shards: 1 }


  #document_type '_doc' #needed?
end
