# frozen_string_literal: true

require 'rails_helper'

describe ES do
  describe '.client' do
    subject(:client) { ES.client }

    it { is_expected.to be_an Elasticsearch::Transport::Client }

    it 'can connect to Elasticsearch' do
      expect(client.ping).to eq(true)
    end

    xit 'uses a persistent connection'
  end

  describe '.collection_repository' do
    
  end
end
