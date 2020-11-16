class DocumentRepository
  include Elasticsearch::Persistence::Repository
  include Elasticsearch::Persistence::Repository::DSL

  extend NamespacedIndex

  klass Document

  #index_name Document.index_namespace #FIXME
 client DEFAULT_CLIENT

 #FIXME - this shouldnt be one shard in prod 
 settings index: { number_of_shards: 1 }

    def serialize(document)
      puts "SERIALIZING"
      # FIXME
      doc_hash = ActiveSupport::HashWithIndifferentAccess.new document.to_hash
      #doc_hash = document.to_hash
      puts "DOC HASH BEING SERIALIZED: #{doc_hash}"
      Serde.serialize_hash(doc_hash, doc_hash[:language], Document::LANGUAGE_FIELDS)
    end

    def deserialize(hash)
      puts 'deserializing'
      doc_hash = hash['_source']
      puts doc_hash
      deserialized_hash = Serde.deserialize_hash(doc_hash, doc_hash['language'], Document::LANGUAGE_FIELDS)

      puts "deserialized_hash: #{deserialized_hash}"
      document = Document.new deserialized_hash
      document.instance_variable_set :@_id, hash['_id']
      document.instance_variable_set :@_index, hash['_index']
      document.instance_variable_set :@_type, hash['_type']
      document.instance_variable_set :@_version, hash['_version']

      document.instance_variable_set :@hit, Hashie::Mash.new(hash.except('_index', '_type', '_id', '_version', '_source'))

      document.instance_variable_set(:@persisted, true)
      document
    end

  #document_type '_doc' #needed?
end
