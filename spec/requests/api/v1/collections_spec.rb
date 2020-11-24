require 'rails_helper'

describe API::V1::Collections do
  let(:valid_session) do
    env_secrets = Rails.application.config_for(:secrets)
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(
      env_secrets['admin_user'], env_secrets['admin_password']
    )
    { 'HTTP_AUTHORIZATION' => credentials }
  end
  let(:valid_params) do
    { handle: 'agency_blogs', token: 'secret' }
  end
  let(:allow_updates) { true }
  let(:maintenance_message) { nil }
  let(:yaml) do
    YAML.load_file("#{Rails.root}/config/elasticsearch.yml").presence
  end
  let(:client) do
    DEFAULT_CLIENT

  end
  #FIXME: use ES transport methods
  let(:collection_repository) do
    CollectionRepository.new(index_name: [Rails.env, I14y::APP_NAME, 'collections', 'v1'].join('-'))
  end
  let(:document_repository) do
    #yuck
    DocumentRepository.new(index_name: DocumentRepository.index_namespace('agency_blogs'))
  end

  before do
    I14y::Application.config.updates_allowed = allow_updates
    I14y::Application.config.maintenance_message = maintenance_message
    client.delete_by_query(
      index: collection_repository.index_name,
      q: '*:*',
      conflicts: 'proceed'
    )
  end

  after do
    I14y::Application.config.updates_allowed = true
  end

  describe 'POST /api/v1/collections' do
    context 'success case' do
      before do
        puts 'posting'
        post '/api/v1/collections', params: valid_params, headers: valid_session
        collection_repository.refresh_index!
      end

      it 'returns success message as JSON' do
        expect(response.status).to eq(201)
        expect(JSON.parse(response.body)).to match(
          hash_including('status' => 200,
                         'developer_message' => 'OK',
                         'user_message' => 'Your collection was successfully created.')
        )
      end

      it 'uses the collection handle as the Elasticsearch ID' do
        expect(collection_repository.find('agency_blogs')).to be_present
      end

      it 'stores the appropriate fields in the Elasticsearch collection' do
        collection = collection_repository.find('agency_blogs')
        expect(collection.token).to eq('secret')
      end

      it_behaves_like 'a data modifying request made during read-only mode'
    end

    context 'a required parameter is empty/blank' do
      before do
        invalid_params = {}
        post '/api/v1/collections', params: invalid_params, headers: valid_session
      end

      it 'returns failure message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)).to match(
          hash_including('status' => 400,
                         'developer_message' => 'handle is missing, handle is empty, token is missing, token is empty')
        )
      end
    end

    context 'handle uses illegal characters' do
      let(:invalid_params) do
        { handle: 'agency-blogs', token: 'secret' }
      end

      before do
        post '/api/v1/collections', params: invalid_params, headers: valid_session
      end

      it 'returns failure message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)).to match(
          hash_including('status' => 400,
                         'developer_message' => 'handle is invalid')
        )
      end
    end

    context 'failed authentication/authorization' do
      before do
        bad_credentials = ActionController::HttpAuthentication::Basic.encode_credentials 'nope', 'wrong'

        valid_session = { 'HTTP_AUTHORIZATION' => bad_credentials }
        post '/api/v1/collections', params: valid_params, headers: valid_session
      end

      it 'returns error message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)).to match(
          hash_including('status' => 400,
                         'developer_message' => 'Unauthorized')
        )
      end
    end

    describe 'something terrible happens' do
      before do
        allow(Collection).to receive(:new) { raise_error(Exception) }
        post '/api/v1/collections', params: valid_params, headers: valid_session
      end

      it 'returns failure message as JSON' do
        expect(response.status).to eq(500)
        expect(JSON.parse(response.body)).to match(
          hash_including('status' => 500,
                         'developer_message' => "Something unexpected happened and we've been alerted.")
        )
      end
    end

  end

  describe 'DELETE /api/v1/collections/{handle}' do
    context 'success case' do
      before do
        collection_repository.save(Collection.new(id: 'agency_blogs', token: 'secret'))
        delete '/api/v1/collections/agency_blogs', headers: valid_session
      end

      it 'returns success message as JSON' do
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to match(
          hash_including('status' => 200,
                         'developer_message' => 'OK',
                         'user_message' => 'Your collection was successfully deleted.')
        )
      end

      it 'deletes the collection' do
        expect(collection_repository.exists?('agency_blogs')).to be_falsey
      end

      it_behaves_like 'a data modifying request made during read-only mode'
    end
  end

  describe 'GET /api/v1/collections/{handle}' do
    subject(:get_collection) do
      get '/api/v1/collections/agency_blogs', headers: valid_session
    end

    #FIXME: rspec spec/ --seed 39143
    context 'success case' do
      before do
        #FIXME: DRY UP
        puts 'posting collection'
        #FIXME -don't do this via the api
        post '/api/v1/collections', params: valid_params, headers: valid_session
        #Document.index_name = DocumentRepository.index_namespace('agency_blogs')
        #client.delete_by_query index: Document.index_name, q: '*:*', conflicts: 'proceed'
        
        #FIXME: all this namespaced index stuff...
        # ...and get rid of dependencies on classes
        client.delete_by_query index: DocumentRepository.index_namespace('agency_blogs'), q: '*:*', conflicts: 'proceed'
#        Document.create(hash1)
#        Document.create(hash2)
        document_repository.save(Document.new(hash1))
        document_repository.save(Document.new(hash2))
        document_repository.refresh_index!
        get_collection
      end

      let(:datetime) { DateTime.now.utc }
      let(:hash1) do
        #TODO: find & replace all the _id's
        {
          _id: 'a1',
          language: 'en',
          title: 'title 1 common content',
          description: 'description 1 common content',
          created: Time.now,
          path: 'http://www.agency.gov/page1.html'
        }
      end
      let(:hash2) do
        {
          _id: 'a2',
          language: 'en',
          title: 'title 2 common content',
          description: 'description 2 common content',
          created: Time.now,
          path: 'http://www.agency.gov/page2.html'
        }
      end

      #FIXME:
      #rspec spec/ --seed 61711 --fail-fast
      it 'is successful' do
        expect(response.status).to eq(200)
      end

      xit 'returns success message with Collection stats as JSON' do
        expect(JSON.parse(response.body)).to match(
          hash_including('status' => 200,
                         'developer_message' => 'OK',
                         'collection' => { 'document_total' => 2,
                                           'last_document_sent' => an_instance_of(String),
                                           'token' => 'secret',
                                           'id' => 'agency_blogs',
                                           'created_at' => an_instance_of(String),
                                           'updated_at' => an_instance_of(String) })
        )
      end

    end
  end

  describe 'GET /api/v1/collections/search' do

    context 'success case' do
      before do
        post '/api/v1/collections', params: valid_params, headers: valid_session
        #DEFAULT_CLIENT.delete_by_query index: Document.index_name, q: '*:*', conflicts: 'proceed'
      end

      let(:datetime) { DateTime.now.utc.to_s }
      let(:hash1) { { _id: 'a1',
                      language: 'en',
                      title: 'title 1 common content',
                      description: 'description 1 common content',
                      content: 'content 1 common content',
                      created: datetime,
                      path: 'http://www.agency.gov/page1.html',
                      promote: true, updated: datetime,
                      updated_at: datetime } }
      let(:hash2) { { _id: 'a2',
                      language: 'en',
                      title: 'title 2 common content',
                      description: 'description 2 common content',
                      content: 'other unrelated stuff',
                      created: datetime.to_s,
                      path: 'http://www.agency.gov/page2.html',
                      promote: false, tags: 'tag1, tag2',
                      updated_at: datetime } }

      #FIXME - intermittent failure
      it 'returns highlighted JSON search results' do
        document_repository.save(Document.new(hash1))
        document_repository.save(Document.new(hash2))
        document_repository.refresh_index! #TODO: replace w/ doc create
        #Document.refresh_index!
        #TODO: make 'common contentx' its own spec
        valid_params = { language: 'en', query: 'common contentx', handles: 'agency_blogs' }
        get '/api/v1/collections/search', params: valid_params, headers: valid_session
        expect(response.status).to eq(200)
        metadata_hash = {
                          'total' => 2,
                          'offset' => 0,
                          'suggestion' => { 'text' => 'common content',
                                            'highlighted' => 'common content' }
                        }
=begin
missing suggestion:
           "metadata" => {
         "total" => 2,
        "offset" => 0,
    "suggestion" => nil
  },
=end
        result1 = {
                    'language' => 'en',
                    'created' => datetime,
                    'path' => 'http://www.agency.gov/page1.html',
                    'title' => 'title 1 common content',
                    'description' => 'description 1 common content',
                    'content' => 'content 1 common content',
                    'changed' => datetime
                  }
        result2 = {
                    'language' => 'en',
                    'created' => datetime,
                    'path' => 'http://www.agency.gov/page2.html',
                    'title' => 'title 2 common content',
                    'description' => 'description 2 common content',
                    'changed' => datetime
                  }
        results_array = [result1, result2]
        expect(JSON.parse(response.body)).to match(
          hash_including('status' => 200,
                         'developer_message' => 'OK',
                         'metadata' => metadata_hash,
                         'results' => results_array)
        )
      end

      it 'uses the appropriate parameters for the DocumentSearch' do
        valid_params = {
                         language: 'en',
                         query: 'common content',
                         handles: 'agency_blogs',
                         sort_by_date: 1,
                         min_timestamp: '2013-02-27T10:00:00Z',
                         max_timestamp: '2013-02-27T10:01:00Z',
                         offset: 2**32,
                         size: 3,
                         tags: 'Foo, Bar blat',
                         ignore_tags: 'ignored',
                         include: 'title,description'
                       }
        expected_params = Hashie::Mash.new('language' => :en,
                                           'query' => 'common content',
                                           'handles' => %w(agency_blogs),
                                           'offset' => 2**32,
                                           'size' => 3,
                                           'sort_by_date' => true,
                                           'min_timestamp' => DateTime.parse('2013-02-27T10:00:00Z'),
                                           'max_timestamp' => DateTime.parse('2013-02-27T10:01:00Z'),
                                           'tags' => ['foo', 'bar blat'],
                                           'ignore_tags' => ['ignored'],
                                           'include' => ['title', 'description']
        )
        expect(DocumentSearch).to receive(:new).with(expected_params)
        get '/api/v1/collections/search', params: valid_params, headers: valid_session
      end
    end

    context 'no results' do
      before do
        client.delete_by_query index: collection_repository.index_name, q: '*:*', conflicts: 'proceed'
        post '/api/v1/collections', params: valid_params, headers: valid_session
       # Document.index_name = DocumentRepository.index_namespace('agency_blogs')
        #client.delete_by_query index: Document.index_name, q: '*:*', conflicts: 'proceed'
        client.delete_by_query index: document_repository.index_name, q: '*:*', conflicts: 'proceed'
      end

      it 'returns JSON no hits results' do
        valid_params = { language: 'en', query: 'no hits', handles: 'agency_blogs' }
        get '/api/v1/collections/search', params: valid_params, headers: valid_session
        expect(response.status).to eq(200)
        metadata_hash = { 'total' => 0, 'offset' => 0, 'suggestion' => nil }
        results_array = []
        expect(JSON.parse(response.body)).to match(
          hash_including('status' => 200,
                         'developer_message' => 'OK',
                         'metadata' => metadata_hash,
                         'results' => results_array)
        )
      end

    end

    context 'missing required params' do
      before do
        invalid_params = {}
        get '/api/v1/collections/search', params: invalid_params, headers: valid_session
      end

      it 'returns error message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)).to match(
          hash_including('status' => 400,
                         'developer_message' => 'handles is missing, handles is empty')
        )
      end
    end

    context 'searching across one or more collection handles that do not exist' do
      let(:bad_handle_params) do
        { language: 'en', query: 'foo', handles: 'agency_blogs,missing' }
      end

      before do
        client.delete_by_query index: collection_repository.index_name, q: '*:*', conflicts: 'proceed'
        collection = Collection.new(id: 'agency_blogs', token: 'secret')
        collection_repository.save(collection)
        collection_repository.refresh_index!
        get '/api/v1/collections/search', params: bad_handle_params, headers: valid_session
      end

      it 'returns error message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)).to match(
          hash_including('error' => 'Could not find all the specified collection handles')
        )
      end
    end
  end
end
