# frozen_string_literal: true

module ES
  def self.client
    @client ||= initialize_client
  end

  def self.collection_repository
    @repository ||= CollectionRepository.new
  end

  private

  def self.initialize_client
    puts "INITIALIZING CLIENT"
    config = Rails.application.config_for(:elasticsearch)

    Elasticsearch::Client.new(log: Rails.env.development?,
                              hosts: config['hosts'],
                              user: config['user'],
                              password: config['password'],
                              randomize_hosts: true,
                              retry_on_failure: true,
                              reload_connections: true)
=begin
    if true # Rails.env.development?
      logger = ActiveSupport::Logger.new(STDERR)
      logger.level = Logger::DEBUG
      logger.formatter = proc { |_s, _d, _p, m| "\e[2m#{m}\n\e[0m" }
      DEFAULT_CLIENT.transport.logger = logger
    end
=end
  end
end
