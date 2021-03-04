# frozen_string_literal: true

module TestServices
  module_function

  def create_collections_index
    ES.client.indices.create(index: collections_index_name, include_type_name: true)
    ES.client.indices.put_alias(
      index: collections_index_name,
      name: ES.collection_repository.index_name
    )
  end

  def delete_es_indexes
    ES.client.indices.delete(index: [Rails.env, I14y::APP_NAME, '*'].join('-'))
  end

  def clear_index(index_name)
    ES.client.delete_by_query(
      index: index_name,
      body: {query: {match_all: {}}},
      conflicts: 'proceed',
      refresh: true
    )
  end

  def collections_index_name
    [Rails.env, I14y::APP_NAME, 'collections', 'v1'].join('-')
  end
end
