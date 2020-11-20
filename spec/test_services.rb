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
    index_name = [Rails.env, I14y::APP_NAME, 'collections', 'v1'].join('-')
    DEFAULT_CLIENT.indices.create(index: index_name) unless DEFAULT_CLIENT.indices.exists?(index: index_name)
    DEFAULT_CLIENT.indices.put_alias(
      index: index_name,
      name: index_name.remove('-v1')
    )
  end

  def collections_index_name
    [Rails.env, I14y::APP_NAME, 'collections', 'v1'].join('-')
  end

  def create_documents_index(handle)
    index_name = [Rails.env, I14y::APP_NAME, 'documents', handle, 'v1'].join('-')
    #Using a single shard prevents intermittent relevancy issues in tests
    #https://www.elastic.co/guide/en/elasticsearch/guide/current/relevance-is-broken.html
    #FIXME rescue nil - only create index once
    #TODO: ensure the ag blogs index isn't left behind after collections api spec
    DEFAULT_CLIENT.indices.delete(index: index_name) if DEFAULT_CLIENT.indices.exists?(index: index_name)
    DEFAULT_CLIENT.indices.create(index: index_name, body: { settings: { number_of_shards: 1 } }) unless DEFAULT_CLIENT.indices.exists?(index: index_name)
    DEFAULT_CLIENT.indices.put_alias(
      index: index_name,
      name: index_name.remove('-v1')
    )
  end

  def create_collection(handle: 'agency_blogs', token: 'secret')
    DEFAULT_CLIENT.index(index: collections_index_name,
                         body: { handle: handle, token: token },
                         type: '_doc')
  end

  def rollback_index_changes
    index_pattern = [Rails.env, I14y::APP_NAME, '*'].join('-')
    DEFAULT_CLIENT.delete_by_query(index: index_pattern, q: '*:*', conflicts: 'proceed')
    #need to refresh?
    #log?
  end

  def delete_es_indexes
    DEFAULT_CLIENT.indices.delete(index: [Rails.env, I14y::APP_NAME, '*'].join('-'))
  end
end
