# frozen_string_literal: true

require 'active_model'

class Collection
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations
  include Virtus.model

  attribute :id
  attribute :token

  validates :id, presence: true
  validates :token, presence: true
    # see https://github.com/elastic/elasticsearch-rails/issues/544
  # TODO: add specs
  # maybe do this when serializing?
  attribute :created_at, Time, default: lambda { |o,a| Time.now.utc }
  attribute :updated_at, Time

  #NEED UNIT SPECS
  def document_total
    document_repository.count
  end

  def last_document_sent
    #FIXME: need spec for the rescue condition
    #FIXME: dr.search(size:1, sort: "_id") - simplify
    document_repository.search("*:*", {size:1, sort: "updated_at:desc"}).results.first.updated_at.utc.to_s #rescue nil
  end

  private

  def document_repository #DELEGATE METHODS?
    @document_repository ||= DocumentRepository.new(index_name: DocumentRepository.index_namespace(id))
  end
end
