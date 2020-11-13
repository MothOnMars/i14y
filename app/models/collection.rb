require 'active_model'

class Collection
  #include Elasticsearch::Persistence::Model
    include ActiveModel::Model
  include ActiveModel::Validations
  extend ActiveModel::Callbacks
include Virtus.model

  #FIXME - remove mapping?
  attribute :id, String, mapping: { type: 'keyword' }
  attribute :token, String, mapping: { type: 'keyword' }
  validates :token, presence: true
  #validate id?


  def document_total
    Document.index_name = Document.index_namespace(self.id)
    Document.count
  end

  def last_document_sent
    Document.index_name = Document.index_namespace(self.id)
    Document.search("*:*", {size:1, sort: "updated_at:desc"}).results.first.updated_at.utc.to_s rescue nil
  end

end
