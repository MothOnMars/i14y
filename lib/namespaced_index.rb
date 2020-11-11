module NamespacedIndex
  def index_namespace(handle = nil)
    # MASTER:  [Rails.env, I14y::APP_NAME, self.name.tableize, handle].compact.join('-')

    #[Rails.env, I14y::APP_NAME, self.name.tableize, 'v1'].compact.join('-') #FIXME
    [Rails.env, I14y::APP_NAME, klass.to_s.tableize, handle].compact.join('-')
  end

  # FIXME - this was not in master
  def alias
    index_namespace.remove(/-v.*$/)
  end

  # https://github.com/elastic/elasticsearch-rails/blob/a0f14d96fab54b64cb3b8cbacd6476aba2dfa78d/elasticsearch-persistence/spec/repository_spec.rb#L158
 
end
