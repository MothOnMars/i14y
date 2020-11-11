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

  def create_es_indexes
    binding.pry
    es_collections_index_name = [Rails.env, I14y::APP_NAME, 'collections', 'v1'].join('-')
    CollectionRepository.new.create_index!(index: es_collections_index_name)
    client.indices.put_alias index: es_collections_index_name, name: Collection.alias
   # Elasticsearch::Persistence.client.indices.put_alias index: es_collections_index_name, name: Collection.index_name
  end

  def delete_es_indexes
    #Elasticsearch::Persistence.client.indices.delete(index: [Rails.env, I14y::APP_NAME, '*'].join('-'))
    client.indices.delete(index: [Rails.env, I14y::APP_NAME, '*'].join('-'))
  end
end
