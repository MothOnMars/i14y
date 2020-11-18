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

  def delete_es_indexes
    #Elasticsearch::Persistence.client.indices.delete(index: [Rails.env, I14y::APP_NAME, '*'].join('-'))
    DEFAULT_CLIENT.indices.delete(index: [Rails.env, I14y::APP_NAME, '*'].join('-'))
  end
end
