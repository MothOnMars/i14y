@reindexing_client = Elasticsearch::Client.new(host: 'http://localhost:9268',
                                              user: 'elastic',
                                              password: 'changeme')

abort("Cannot connect to remote cluster") unless @reindexing_client.ping

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

def temporary_settings
#  { settings:
    {
      number_of_shards: 1,
      number_of_replicas: 0,
      refresh_interval: "-1"
    }
#  }
end

def reindex_body(index_name)
  {
    "source": {
      "remote": {
        "host": "#{@host[:protocol]}://#{@host[:host]}:#{@host[:port]}",
        "username": @host[:user],
        "password": @host[:password],
        "socket_timeout": "3m"
      },
      "index": index_name
    },
    "dest": {
      "index": index_name,
    }
  }
end


entity_names.each do |entity_name|
  persistence_model_klass = entity_name.singularize.camelize.constantize # Document < Object
  klass = entity_name.camelize.constantize # Documents < Object
  template_generator = klass.new #Documents.new
  #Elasticsearch::Persistence.client.indices.put_template(name: entity_name,
  Rails.logger.info "adding template for #{entity_name}"
  @reindexing_client.indices.put_template(name: entity_name,
                                          body: template_generator.body,
                                          order: 0)

  wildcard = [persistence_model_klass.index_namespace, '*'].join # "development-i14y-documents*"
  aliases = Elasticsearch::Persistence.client.indices.get_alias(name: wildcard)
  Rails.logger.info "found #{aliases.count} aliases for #{entity_name}"
  aliases.each do |old_es_index_name, alias_names|
    alias_name = alias_names['aliases'].keys.first
    Rails.logger.info "creating index #{old_es_index_name}"
    #persistence_model_klass.index_name = old_es_index_name
    #new_es_index_name = next_version(old_es_index_name)
    @reindexing_client.indices.create(index: old_es_index_name,
                                      body: { settings: temporary_settings })
    Rails.logger.info "reindexing #{old_es_index_name}"
    #puts "Beginning copy of #{persistence_model_klass.count} #{entity_name} from #{old_es_index_name} to #{new_es_index_name}"
    #persistence_model_klass.create_index!(index: new_es_index_name) #TODO: add temporary settings
    #persistence_model_klass.index_name = new_es_index_name 
    remote_reindex(old_es_index_name)
    Rails.logger.info "adding alias #{alias_name} for #{old_es_index_name}"
    @reindexing_client.indices.put_alias(index: old_es_index_name, name: alias_name)
    Rails.logger.info "done reindexing #{alias_name}"
    #puts "New #{new_es_index_name} index now contains #{persistence_model_klass.count} #{entity_name}"
  end
end
