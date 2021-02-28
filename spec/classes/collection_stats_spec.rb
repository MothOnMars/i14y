# frozen_string_literal: true

require 'rails_helper'

describe CollectionStats do
  describe 'initialization' do
    it 'requires a collection' do
      expect { CollectionStats.new }.to raise_error ArgumentError
    end
  end
end
