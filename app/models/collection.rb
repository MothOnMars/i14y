# frozen_string_literal: true

class Collection
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations
  include Virtus.model

  attribute :id, String
  attribute :token, String
  attribute :created_at, Time, default: proc { Time.now.utc }
  attribute :updated_at, Time, default: proc { Time.now.utc }

  validates :token, presence: true

  def document_total
    document_repository.count
    #ES.client.count(index: document_repository.index_name)
  end

  def last_document_sent
    puts document_repository.count

    puts document_repository.search("*:*", {size:1, sort: "updated_at:asc"}).
      results.first.attributes
    document_repository.search("*:*", {size:1, sort: "updated_at:asc"}).
      results.first.updated_at.utc.to_s
  rescue
    nil
  end

  def document_repository
    @document_repository = DocumentRepository.new(
      index_name: DocumentRepository.index_namespace(id)
    )
  end
end

=begin
  def document_total
    ES.client.count(index: document_repository.index_name)
  end

  def last_document_sent
    binding.pry
    ES.client.search(
      index: document_repository.index_name,
      body: {
        "size": 1,
        "sort": {
          "updated_at": "desc"
        }
      }
    )['hits']['hits'].first['_source']['updated_at']
  rescue
    nil
  end

=end
