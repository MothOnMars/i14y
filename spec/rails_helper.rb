# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.include DocumentCrud

  config.infer_spec_type_from_file_location!

  config.before(:suite) do
    require 'test_services'
    #abort('Unable to connect to Elasticsearch') unless ES.client.ping
    TestServices::delete_es_indexes
    TestServices::create_es_indexes
  end

  config.before do
    # FIXME: we should also be able to purge collections, but that causes intermittent failures
    # DO THIS AFTER, NOT BEFORE?
    DEFAULT_CLIENT.delete_by_query index: 'test-i14y-documents*', q: '*:*', conflicts: 'proceed'
  end

  config.after(:suite) do
    TestServices::delete_es_indexes
  end

  config.before :each, elasticsearch: true do
    #fix me - move to api/doc spec?
    begin
      # FIXME
      #document_repository = DocumentRepository.new(index_name: DocumentRepository.index_namespace)
      #Document.create_index!
      #Document.refresh_index!
      #FIXME - this causes random logging 
    rescue => Elasticsearch::Transport::Transport::Errors::NotFound
      # This kills "Index does not exist" errors being written to console
      # by this: https://github.com/elastic/elasticsearch-rails/blob/738c63efacc167b6e8faae3b01a1a0135cfc8bbb/elasticsearch-model/lib/elasticsearch/model/indexing.rb#L268
    rescue StandardError => error
      STDERR.puts "There was an error creating the elasticsearch index for #{Document.name}: #{error.inspect}"
    end
  end

  config.after :each, elasticsearch: true do
    #DEFAULT_CLIENT.indices.delete index: '*documents*'
  end
end

#TODO: move this?
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
