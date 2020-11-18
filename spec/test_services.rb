module TestServices
  module_function

  def client #FIXME
    yaml = YAML.load_file("#{Rails.root}/config/elasticsearch.yml").presence
    Elasticsearch::Client.new(log: Rails.env.development?,
                                                              hosts: yaml['hosts'],
                                                              user: yaml['user'],
                                                              password: yaml['password'],
                                                              randomize_hosts: true,
                                                              retry_on_failure: true,
                                                              reload_connections: true)
  end

  # TODO: rename - only collections
  def create_es_indexes
    collections_index_name = [Rails.env, I14y::APP_NAME, 'collections', 'v1'].join('-')
    collection_repository = CollectionRepository.new(index_name: collections_index_name)
    collection_repository.create_index!
    #FIXME - do we even need the alias?
    DEFAULT_CLIENT.indices.put_alias index: collections_index_name, name: collections_index_name.remove('-v1')
    # alias is just the namespaced index wtihout the v1
    #client.indices.put_alias index: es_collections_index_name, name: Collection.alias 
   # Elasticsearch::Persistence.client.indices.put_alias index: es_collections_index_name, name: Collection.index_name
  end

  def create_documents_index(handle)
    es_documents_index_name = [DocumentRepository.index_namespace(handle), 'v1'].join('-')
    #Using a single shard prevents intermittent relevancy issues in tests
    #https://www.elastic.co/guide/en/elasticsearch/guide/current/relevance-is-broken.html
    document_repository =  DocumentRepository.new(settings: { index: { number_of_shards: 1 } }, index_name: es_documents_index_name)
    document_repository.create_index!#(index_name: es_documents_index_name)
    DEFAULT_CLIENT.indices.put_alias index: es_documents_index_name,
                                                        name: DocumentRepository.index_namespace(handle)

  end

  def delete_es_indexes
    #Elasticsearch::Persistence.client.indices.delete(index: [Rails.env, I14y::APP_NAME, '*'].join('-'))
    DEFAULT_CLIENT.indices.delete(index: [Rails.env, I14y::APP_NAME, '*'].join('-'))
  end
end

=begin
  let(:document_repository) do
    #FIXME
    es_documents_index_name = [DocumentRepository.index_namespace('agency_blogs'), 'v1'].join('-')
    #Using a single shard prevents intermittent relevancy issues in tests
    #https://www.elastic.co/guide/en/elasticsearch/guide/current/relevance-is-broken.html
    DocumentRepository.new(settings: { index: { number_of_shards: 1 } }, index_name: es_documents_index_name)
  end


  before do
    es_documents_index_name = [DocumentRepository.index_namespace('agency_blogs'), 'v1'].join('-')
    #FIXME: delete by query
    #Using a single shard prevents intermittent relevancy issues in tests
    #https://www.elastic.co/guide/en/elasticsearch/guide/current/relevance-is-broken.html
    #DocumentRepository.settings(index: { number_of_shards: 1 })
    document_repository.create_index!#(index_name: es_documents_index_name)
    client.indices.put_alias index: es_documents_index_name,
                                                        name: DocumentRepository.index_namespace('agency_blogs')
    #Document.index_name = Document.index_namespace('agency_blogs')
  end
=end
