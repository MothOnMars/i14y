# frozen_string_literal: true

require 'rails_helper'

describe Collection do
  subject(:collection) { Collection.new(collection_params) }
  let(:collection_params) do
    {
      id: '123',
      token: 'collection_token'
    }
  end

  describe 'validations' do
    context 'with valid parameters' do
      it { is_expected.to be_valid }
    end

    it { is_expected.to validate_presence_of(:token) }
    #?it { is_expected.to validate_presence_of(:id) }
  end

end
