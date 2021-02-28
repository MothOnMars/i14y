# frozen_string_literal: true

class CollectionStats
  attr_reader :collection

  def initialize(collection)
    @collection = collection
  end

  def document_total
    0
  end
end
