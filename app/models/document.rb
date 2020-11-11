require 'active_model' #remove?
#require 'active_model/callbacks'

#good ref for what used to be included with es persistence model:
#https://github.com/elastic/elasticsearch-rails/blob/7aa03e87b7fee71007ff7aa1a6fb452de298587e/elasticsearch-persistence/lib/elasticsearch/persistence/model.rb#L38
class Document
  include ActiveModel::Model
  include ActiveModel::Validations
  extend ActiveModel::Callbacks #delete me?
 # extend NamespacedIndex
 # include Elasticsearch::Persistence::Model
  include Virtus.model
 # include ActiveModel::Model
 #   include ActiveModel::Model

  define_model_callbacks :save #delete me?

  #delegate :category, to: :video
  #delegate :index_namespace, to: DocumentRepository

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

  #before_save { self.changed = changed.presence || created }

  LANGUAGE_FIELDS = [:title, :description, :content]

end
