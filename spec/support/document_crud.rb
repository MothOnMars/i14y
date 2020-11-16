module DocumentCrud

  #fixme
  def document_create(params)
    #FIXME - need better helper
    #create in batches, then refresh
    puts 'creating doc without API'
    document = Document.new(params)
    document_repository.save(document)
    document_repository.refresh_index!
  end

  def api_post(params,session)
    post "/api/v1/documents", params: params, headers: session
    document_repository.refresh_index!
  end

  def api_put(path,params, session)
    put path, params: params, headers: session
    document_repository.refresh_index!
  end

  def api_delete(path,session)
    delete path, headers: session
  end

end
