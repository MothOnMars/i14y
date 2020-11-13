require 'rails_helper'
require 'uri'

describe API::V1::Documents, elasticsearch: true do
  let(:id) { 'some really!weird@id.name' }
  let(:language) { 'hy' }
  let(:doc_params) do
    { document_id: id,
      title:       'my title',
      path:        'http://www.gov.gov/goo.html',
      description: 'my desc',
      promote:     true,
      language:    language,
      content:     'my content',
      tags:        'Foo, Bar blat' }
  end
  let(:valid_session) do
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials 'test_index', 'test_key'
    { HTTP_AUTHORIZATION: credentials }
  end
  let(:allow_updates) { true }
  let(:maintenance_message) { nil }
  let(:document_repository) { DocumentRepository.new(index_name: DocumentRepository.index_namespace('test_index')) }

  before(:all) do
    yaml = YAML.load_file("#{Rails.root}/config/secrets.yml")
    env_secrets = yaml[Rails.env]
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials env_secrets['admin_user'], env_secrets['admin_password']
    valid_collection_session = { HTTP_AUTHORIZATION: credentials }
    valid_collection_params = { handle: 'test_index', token: 'test_key' }
    #FIXME: don't do this with a post
    post '/api/v1/collections', params: valid_collection_params, headers: valid_collection_session
    #Document.index_name = DocumentRepository.index_namespace('test_index')
  end

  before do
    I14y::Application.config.updates_allowed = allow_updates
    I14y::Application.config.maintenance_message = maintenance_message
  end

  after do
    I14y::Application.config.updates_allowed = true
  end

  describe 'POST /api/v1/documents' do
    subject(:post_document) do
      post "/api/v1/documents", params: doc_params, headers: valid_session
    end

    context 'success case' do
      before do
        post_document
      end

      it 'returns success message as JSON' do
        expect(response.status).to eq(201)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 200,
                                     'developer_message' => 'OK',
                                     'user_message' => 'Your document was successfully created.'))
      end

      it 'uses the collection handle and the document_id in the Elasticsearch ID' do
        expect(document_repository.find(id)).to be_present
      end

      it 'stores the appropriate fields in the Elasticsearch document' do
        document = document_repository.find(id)
        expect(document.path).to eq('http://www.gov.gov/goo.html')
        expect(document.promote).to be_truthy
        expect(document.title).to eq('my title')
        expect(document.description).to eq('my desc')
        expect(document.content).to eq('my content')
        expect(document.tags).to match_array(['bar blat', 'foo'])
      end

      it_behaves_like 'a data modifying request made during read-only mode'
    end

    describe 'trying to create an existing document' do
      before do
        #FIXME - need better helper method
        document_create(doc_params.merge(id: 'its_a_dupe'))

        api_post doc_params.merge(document_id: 'its_a_dupe'), valid_session
      end

      it 'returns failure message as JSON' do
        expect(response.status).to eq(422)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 422,
                                     'developer_message' => 'Document already exists with that ID'))
      end
    end

    describe 'invalid language param' do
      let(:language) { 'qq' }

      #CLEAN THIS UP
      before do
        post_document
      end

      it 'returns failure message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 400,
                                     'developer_message' => 'language does not have a valid value'))
      end
    end

    context 'when the id contains a slash' do
      let(:id) { 'a1/234' }
      #FIXME
      before { post_document }

      it 'returns failure message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 400,
                                     'developer_message' => "document_id cannot contain any of the following characters: ['/']"))
      end
    end

    context 'when the id is larger than 512 bytes' do
      let(:id) do
        two_byte_character = '\u00b5'
        string_with_513_bytes_but_only_257_characters = 'x' + two_byte_character * 256
      end

      before do
        #fixme
        post_document
      end

      it 'returns failure message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 400,
                                     'developer_message' => 'document_id cannot be more than 512 bytes long'))
      end
    end

    context 'when the language param is missing'  do
      before do
        doc_params = { document_id: 'a1234',
                         title:       'my title',
                         path:        'http://www.gov.gov/goo.html',
                         created:     '2013-02-27T10:00:00Z',
                         description: 'my desc' }
        api_post doc_params, valid_session
      end

      it 'uses English (en) as default' do
        expect(document_repository.find('a1234').language).to eq('en')
      end
    end

    pending 'a required parameter is empty/blank' do
      before do
        indoc_params = doc_params.merge({ 'title' => ' ' })
        api_post indoc_params, valid_session
      end

      it 'returns failure message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 400,
                                     'developer_message' => 'title is empty'))
      end
    end

    pending 'path URL is poorly formatted' do
      before do
        indoc_params = { document_id: 'a1234',
                           title:       'weird URL with blank',
                           description: 'some description',
                           path:        'http://www.gov.gov/ goo.html',
                           created:     '2013-02-27T10:00:00Z' }
        api_post indoc_params, valid_session
      end

      it 'returns failure message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 400,
                                     'developer_message' => 'path is invalid'))
      end
    end

    pending 'failed authentication/authorization' do
      before do
        doc_params = { document_id: 'a1234',
                         title:       'my title',
                         path:        'http://www.gov.gov/goo.html',
                         created:     '2013-02-27T10:00:00Z',
                         description: 'my desc',
                         promote:     true }
        bad_credentials = ActionController::HttpAuthentication::Basic.encode_credentials 'nope', 'wrong'

        valid_session = { HTTP_AUTHORIZATION:  bad_credentials }
        api_post doc_params, valid_session
      end

      it 'returns error message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 400,
                                     'developer_message' => 'Unauthorized'))
      end
    end

    pending 'something terrible happens during authentication' do
      before do
        allow(Collection).to receive(:find).and_raise(Elasticsearch::Transport::Transport::Errors::BadRequest)
        doc_params = { document_id: 'a1234',
                         title:       'my title',
                         path:        'http://www.gov.gov/goo.html',
                         created:     '2013-02-27T10:00:00Z',
                         description: 'my desc',
                         promote:    true }
        api_post doc_params, valid_session
      end

      it 'returns error message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 400,
                                     'developer_message' => 'Unauthorized'))
      end
    end

    pending 'something terrible happens creating the document' do
      before do
        allow(Document).to receive(:new) { raise_error(Exception) }
        doc_params = { document_id: 'a1234',
                         title:       'my title',
                         path:        'http://www.gov.gov/goo.html',
                         created:     '2013-02-27T10:00:00Z',
                         description: 'my desc',
                         promote:     true }
        api_post doc_params, valid_session
      end

      it 'returns failure message as JSON' do
        expect(response.status).to eq(500)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 500,
                                     'developer_message' => "Something unexpected happened and we've been alerted."))
      end
    end

  end

  pending 'PUT /api/v1/documents/{document_id}' do
    let(:update_params) do
      {
        title:       'new title',
        description: 'new desc',
        content:     'new content',
        path:        'http://www.next.gov/updated.html',
        promote:     false,
        tags:        'new category',
        changed:     '2016-01-01T10:00:01Z',
        click_count: 1000
      }
    end

    context 'success case' do
      before do
        document_create(id:           id,
                        language:    'en',
                        title:       'hi there 4',
                        description: 'bigger desc 4',
                        content:     'huge content 4',
                        created:     2.hours.ago,
                        updated:     Time.now,
                        promote:     true,
                        path:        'http://www.gov.gov/url4.html')

        api_put "/api/v1/documents/#{URI.encode(id)}", update_params, valid_session
      end

      it 'returns success message as JSON' do
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 200,
                                     'developer_message' => 'OK',
                                     'user_message' => 'Your document was successfully updated.'))
      end

      it 'updates the document' do
        document = Document.find(id)
        expect(document.path).to eq('http://www.next.gov/updated.html')
        expect(document.promote).to be_falsey
        expect(document.title).to eq('new title')
        expect(document.description).to eq('new desc')
        expect(document.content).to eq('new content')
        expect(document.tags).to match_array(['new category'])
        expect(document.changed).to eq('2016-01-01T10:00:01Z')
        expect(document.click_count).to eq(1000)
      end

      it_behaves_like 'a data modifying request made during read-only mode'
    end
  end

  pending 'DELETE /api/v1/documents/{document_id}' do
    context 'success case' do
      before do
        document_create(id:          id,
                        language:    'en',
                        title:       'hi there 4',
                        description: 'bigger desc 4',
                        content:     'huge content 4',
                        created:     2.hours.ago,
                        updated:     Time.now,
                        promote:     true,
                        path:        'http://www.gov.gov/url4.html')

        api_delete "/api/v1/documents/#{URI.encode(id)}", valid_session
      end

      it 'returns success message as JSON' do
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 200,
                                     'developer_message' => 'OK',
                                     'user_message' => 'Your document was successfully deleted.'))
      end

      it 'deletes the document' do
        expect(Document.exists?(id)).to be_falsey
      end

      it_behaves_like 'a data modifying request made during read-only mode'
    end

    context 'deleting a non-existent document' do
      before do
        api_delete '/api/v1/documents/non_existent_document_id', valid_session
      end

      it 'returns error message as JSON' do
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body))
            .to match(hash_including('status' => 400,
                                     'developer_message' => 'Resource could not be found.'))
      end
    end
  end
end
