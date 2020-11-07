module NamespacedIndex
  def index_namespace(handle = nil)
   # [Rails.env, I14y::APP_NAME, klass.to_s.tableize, handle].compact.join('-')
    [Rails.env, I14y::APP_NAME, klass.to_s.tableize, 'v1'].compact.join('-') #FIXME
  end

  def alias
    index_namespace.remove(/-v.*$/)
  end

end
