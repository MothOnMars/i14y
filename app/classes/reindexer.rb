@reindexing_client = Elasticsearch::Client.new(host: 'http://es68x1:9200',
                                              user: 'elastic',
                                              password: 'changeme')

@client = Elasticsearch::Persistence.client
@host = @client.transport.hosts.first

entity_names = %w[documents collections]

def next_version(index_name)
  matches = index_name.match(/(.*-v)(\d+)/)
  "#{matches[1]}#{matches[2].succ}"
end

def stream2es(old_es_index_url, new_es_index_url, timestamp = nil)
  options = ["--source #{old_es_index_url}", "--target #{new_es_index_url}"]
  if timestamp.present?
    hash = { query: { filtered: { filter: { range: { updated_at: { gte: timestamp } } } } } }
    options << "--query '#{hash.to_json}'"
  end
  result = `#{Rails.root.join('vendor', 'stream2es')} es #{options.join(' ')}`
  puts "Stream2es completed", result
end

def move_alias(alias_name, old_index_name, new_index_name)
  update_aliases_hash = { body:
                            { actions: [
                              { remove: { index: old_index_name, alias: alias_name } },
                              { add: { index: new_index_name, alias: alias_name } }
                            ] } }
  Elasticsearch::Persistence.client.indices.update_aliases(update_aliases_hash)
end

def handle_failures(task, index)
  Rails.logger.info task
  failures = task['error']
  return unless failures&.present?

  Rails.logger.error("Error migrating #{index}:\n#{failures}")
end

def remote_reindex(index)
  Rails.logger.info("Remote reindexing #{index}")
  task_id = (@reindexing_client.reindex(body: reindex_body(index),
                                 wait_for_completion: false))['task']
  while @reindexing_client.tasks.get(task_id: task_id)['completed'] == false
    Rails.logger.info("Reindex in progress: #{index}")
    sleep 10
  end
  Rails.logger.info("Reindex complete: #{index}")
  handle_failures(reindex_task(task_id), index)
end

def reindex_body(old_es_index_name, new_es_index_name)
  {
    "source": {
      "remote": {
        "host": "#{@host[:protocol]}://#{@host[:host]}:#{@host[:port]}",
        "username": @host[:user],
        "password": @host[:password],
        "socket_timeout": "3m"
      },
      "index": index
    },
    "dest": {
      "index": index,
    }
  }
end


entity_names.each do |entity_name|
  entity_name = args.entity_name # "collections"
  persistence_model_klass = entity_name.singularize.camelize.constantize # Document < Object
  klass = entity_name.camelize.constantize # Documents < Object
  template_generator = klass.new #Documents.new
  #Elasticsearch::Persistence.client.indices.put_template(name: entity_name,
  @reindexing_client.indices.put_template(name: entity_name,
                                          body: template_generator.body,
                                          order: 0)

  wildcard = [persistence_model_klass.index_namespace, '*'].join # "development-i14y-documents*"
  aliases = Elasticsearch::Persistence.client.indices.get_alias(name: wildcard)
  aliases.each do |old_es_index_name, alias_names|
    alias_name = alias_names['aliases'].keys.first
    persistence_model_klass.index_name = old_es_index_name
    new_es_index_name = next_version(old_es_index_name)
    puts "Beginning copy of #{persistence_model_klass.count} #{entity_name} from #{old_es_index_name} to #{new_es_index_name}"
    persistence_model_klass.create_index!(index: new_es_index_name) #TODO: add temporary settings
    persistence_model_klass.index_name = new_es_index_name 
    remote_reindex(old_es_index_name)
    @reindexing_client.indices.put_alias(index: old_es_index_name, name: alias_name)
    #since_timestamp = Time.now
    #host_hash = Elasticsearch::Persistence.client.transport.hosts.first
    #base_url = "#{host_hash[:protocol]}://#{host_hash[:host]}:#{host_hash[:port]}/"
    #old_es_index_url = base_url + old_es_index_name
    #new_es_index_url = base_url + new_es_index_name
    #stream2es(old_es_index_url, new_es_index_url)
    #move_alias(alias_name, old_es_index_name, new_es_index_name)
    #stream2es(old_es_index_url, new_es_index_url, since_timestamp)
    puts "New #{new_es_index_name} index now contains #{persistence_model_klass.count} #{entity_name}"
    #Elasticsearch::Persistence.client.indices.delete(index: old_es_index_name) #TODO: make this a separate rake task
  end
end



# put template
# iterate through aliases



=begin
@klasses = [MrssPhoto,
            MrssProfile,
            FlickrPhoto,
            FlickrProfile,
            InstagramPhoto,
            InstagramProfile]
@client = Elasticsearch::Persistence.client
#fixme
@reindexing_client = Elasticsearch::Client.new(host: 'http://es68x1:9200',
                                              user: 'elastic',
                                              password: 'changeme')

abort("Cannot connect to new cluster") unless @reindexing_client.ping

@host = @client.transport.hosts.first

def temporary_settings
  { settings:
    {
      number_of_shards: 1,
      number_of_replicas: 0,
      refresh_interval: "-1"
    }
  }
end

def reindex_body(index)
  {
  "source": {
    "remote": {
      "host": "#{@host[:protocol]}://#{@host[:host]}:#{@host[:port]}",
      "username": @host[:user],
      "password": @host[:password],
      "socket_timeout": "3m"
    },
    "index": index
  },
  "dest": {
    "index": index,
  }
}
end

def index(klass)
  @client.indices.get_alias(name: klass.index_name).keys.first
end

def create_index(klass)
  @reindexing_client.indices.create(
    index: index(klass),
    body: {settings: klass.settings,
           mappings: klass.mappings}
  )
end

def put_temporary_settings(index)
  @reindexing_client.indices.put_settings(index: index, body: temporary_settings)
end

def reindex_task(task_id)
  @reindexing_client.tasks.get(task_id: task_id)
end

def handle_failures(task, index)
  Rails.logger.info task
  failures = task['error']
  return unless failures&.present?

  Rails.logger.error("Error migrating #{index}:\n#{failures}")
end

def remote_reindex(index)
  Rails.logger.info("Remote reindexing #{index}")
  task_id = (@reindexing_client.reindex(body: reindex_body(index),
                                 wait_for_completion: false))['task']
  while @reindexing_client.tasks.get(task_id: task_id)['completed'] == false
    Rails.logger.info("Reindex in progress: #{index}")
    sleep 10
  end
  Rails.logger.info("Reindex complete: #{index}")
  handle_failures(reindex_task(task_id), index)
end

def update_settings(klass)
  @reindexing_client.indices.put_settings(index: index(klass),
                                          body: klass.settings)
end

#TODO: use reindexing settings
def reindex(klass)
  begin
    create_index(klass)
    remote_reindex(index(klass))
    @reindexing_client.indices.put_alias(index: index(klass), name: klass.alias_name)
  rescue => e
    Rails.logger.error("Error reindexing #{klass}: #{e}\n#{e.backtrace.join("\n")}")
  end
end

def reindex_all
  @klasses.each do |klass|
    reindex(klass)
  end
end

=end
