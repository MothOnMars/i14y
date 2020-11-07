require 'active_model' #remove?
#require 'active_model/callbacks'

class Document
  include ActiveModel::Model
  include ActiveModel::Validations
  extend ActiveModel::Callbacks
 # include Elasticsearch::Persistence::Model
  include Virtus.model
 # include ActiveModel::Model
 #   include ActiveModel::Model

  define_model_callbacks :save

  attribute :path, String, mapping: { type: 'keyword' }
  validates :path, presence: true
  attribute :language, String, mapping: { type: 'keyword' }
  validates :language, presence: true
  attribute :created, DateTime

  attribute :title, String
  attribute :description, String
  attribute :content, String

  attribute :updated, DateTime
  attribute :changed, DateTime
  attribute :promote, Boolean
  attribute :tags, String, mapping: { type: 'keyword' }
  attribute :click_count, Integer

  before_save { self.changed = changed.presence || created }

  LANGUAGE_FIELDS = [:title, :description, :content]

end
