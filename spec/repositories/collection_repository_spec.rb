# frozen_string_literal: true

require 'rails_helper'

describe CollectionRepository do
  subject(:repository) { described_class.new }

  it 'stores collections' do
    expect(repository.klass).to eq(Collection)
  end
end
