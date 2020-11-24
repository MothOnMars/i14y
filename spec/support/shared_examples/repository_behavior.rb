shared_examples_for 'a repository' do
  describe 'serialization' do
    let(:klass_instance) { repository.klass.new }
    subject(:serialize) { repository.serialize(klass_instance) }

    it { is_expected.to be_a Hash }
  end

  it 'can connect to Elasticsearch' do
    expect(repository.client.ping).to be(true)
  end
end
