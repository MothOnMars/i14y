@reindexing_client = Elasticsearch::Client.new(host: 'http://localhost:9268',
                                              user: 'elastic',
                                              password: 'changeme')

abort("Cannot connect to remote cluster") unless @reindexing_client.ping

@client = Elasticsearch::Persistence.client
@host = @client.transport.hosts.first

entity_names = %w[documents collections]


def reindex_task(task_id)
  #@reindexing_client.tasks.get(task_id: task_id) only works w/ modern gem
  @reindexing_client.perform_request('GET', "_tasks/#{task_id}").body
end

def handle_failures(task, index)
  Rails.logger.info task
  failures = task['error']
  return unless failures&.present?

  Rails.logger.error("Error migrating #{index}:\n#{failures}")
end

def create_new_index(index_name)
  Rails.logger.info "Creating index #{index_name}"
  @reindexing_client.indices.create(index: index_name,
                                    body: { settings: { refresh_interval: '-1',
                                                        number_of_replicas: 0,
                                                        number_of_shards: shards(index_name) }})
end

def process_alias(es_alias)
  old_es_index_name = es_alias[0]
  alias_names = es_alias[1]
  alias_name = alias_names['aliases'].keys.first
  create_new_index(old_es_index_name)
  remote_reindex(old_es_index_name)
  Rails.logger.info "adding alias #{alias_name} for #{old_es_index_name}"
  @reindexing_client.indices.put_alias(index: old_es_index_name, name: alias_name)
rescue => error
  Rails.logger.error "Error processing #{es_alias}\n#{error}\n#{error.backtrace.first(2)}"
end

def remote_reindex(index)
  Rails.logger.info("Remote reindexing #{index}")
  task_id = (@reindexing_client.reindex(body: reindex_body(index),
                                 wait_for_completion: false))['task']
  while reindex_task(task_id)['completed'] == false
    Rails.logger.info("Reindex in progress: #{index}")
    sleep 10
  end
  Rails.logger.info("Reindex complete: #{index}")
  handle_failures(reindex_task(task_id), index)
end

def permanent_settings
  {
    number_of_replicas: 1,
    refresh_interval: "1s"
  }
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

def shards(index_name)
  @client.indices.get_settings(index: index_name)[index_name]['settings']['index']['number_of_shards']
end
#TODO: put in ticket re. upgrading ES gems

entity_names.each do |entity_name|
  persistence_model_klass = entity_name.singularize.camelize.constantize # Document < Object
  klass = entity_name.camelize.constantize # Documents < Object
  template_generator = klass.new #Documents.new
  Rails.logger.info "Adding template for #{entity_name}"
  @reindexing_client.indices.put_template(name: entity_name,
                                          body: template_generator.body,
                                          order: 0)

  wildcard = [persistence_model_klass.index_namespace, '*'].join # "development-i14y-documents*"
  aliases = Elasticsearch::Persistence.client.indices.get_alias(name: wildcard)
  Rails.logger.info "found #{aliases.count} aliases for #{entity_name}"
  aliases.each do |es_alias|
    process_alias(es_alias)
  end
  @reindexing_client.indices.put_settings(index: '*i14y*', body: { settings: permanent_settings })
end
