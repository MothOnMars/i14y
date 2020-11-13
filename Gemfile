source 'https://rubygems.org'
gem 'rails', ' ~> 5.2.0'
#TODO: REMOVE NON API GEMS
#TODO: REMOVE RACK-CORS?, newrelic, capistrano...
gem 'rack-cors', '~> 1.0.5'
gem 'grape', '~> 1.3.2'

gem 'jbuilder', '~> 2.7'

gem 'capistrano', '~> 3.9.0'
gem 'capistrano-rails', '~> 1.3'
gem 'capistrano-bundler', '~> 1.2'
gem 'capistrano-passenger', '~> 0.2.0'

#
#The elasticsearch library is a wrapper for two separate libraries:
# elasticsearch-transport, which provides a low-level Ruby client for connecting to an Elasticsearch cluster
#elasticsearch-api, which provides a Ruby API for the Elasticsearch RESTful API
#
# Upgrade guide: https://www.elastic.co/blog/activerecord-to-repository-changing-persistence-patterns-with-the-elasticsearch-rails-gem
gem "elasticsearch-persistence", '~> 6.0'#, require: 'elasticsearch/persistence/model'
gem 'elasticsearch', '~> 6.0' #, '5.0.4'
gem 'elasticsearch-model', '~> 6.0' #this isnt' needed - dependency of es persistence
gem 'elasticsearch-dsl', '~> 0.1.9'
gem 'elasticsearch-transport', '~> 6.0' #not needed
gem 'elasticsearch-api', '~> 6.0' #not needed
gem 'virtus'

gem 'newrelic_rpm', '~> 4.2'
gem 'airbrake', '~> 7.1'

#TODO: add rubocop-rspec

#gem 'patron', '~> 0.10.0'

group :development, :test do
  gem 'rspec-rails', '~> 3.7'
  gem 'pry-byebug', '~> 3.4'
  gem 'pry-rails', '~> 0.3'
  gem 'faker', '~> 1.7'
  gem 'awesome_print', '~> 1.8' #To enable in Pry: https://github.com/awesome-print/awesome_print#pry-integration
  # Updating rubocop? Update & run mry to ensure rubocop.yml is updated:
  # https://github.com/pocke/mry#usage (include the target version to add new cops)
  # Also bump the rubocop channel in .codeclimate.yml:
  # https://docs.codeclimate.com/v1.0/docs/rubocop#section-using-rubocop-s-newer-versions
  gem 'rubocop', '0.52.1'
  gem 'mry', '~> 0.52.0'
  gem 'listen'
  gem 'puma',  '~> 4.3'
end

group :test do
  gem 'simplecov', '~> 0.13.0', require: false
  gem "codeclimate-test-reporter", '~> 1.0.8', require: nil
  gem 'fuubar', '~> 2.2'
end
