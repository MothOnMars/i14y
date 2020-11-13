require 'rails_helper'

describe Document do
  let(:valid_params) do
    {
      id: 'a123',
      language: 'en',
      path: 'http://www.agency.gov/page1.html',
      title: 'My Title',
      created: DateTime.now,
      changed: DateTime.now,
      description: 'My Description',
      content: 'some content',
      promote: true,
      tags: 'this,that'
    }
  end
  let(:repository) do
    handle = 'test_index'
    es_documents_index_name = [DocumentRepository.index_namespace(handle), 'v1'].join('-')
    DocumentRepository.new(index_name: es_documents_index_name)
  end

  before(:all) do
    handle = 'test_index'
    es_documents_index_name = [DocumentRepository.index_namespace(handle), 'v1'].join('-')
    DocumentRepository.new.create_index!(index: es_documents_index_name)
    #DEFAULT_CLIENT.indices.put_alias index: es_documents_index_name, #nix?
    #                                                    name: Document.index_namespace(handle)
   # Document.index_name = Document.index_namespace(handle)
  end

  after do
    repository.delete_index!
  end

  describe '.create' do
    context 'when language fields contain HTML/CSS and HTML entities' do
      let(:html) do
        <<~HTML
          <div style="height: 100px; width: 100px;"></div>
          <p>hello & goodbye!</p>
        HTML
      end

      before do
        repository.save(id: 'a123',
                        language: 'en',
                        title: '<b><a href="http://foo.com/">foo</a></b><img src="bar.jpg">',
                        description: html,
                        created: DateTime.now,
                        path: 'http://www.agency.gov/page1.html',
                        content: "this <b>is</b> <a href='http://gov.gov/url.html'>html</a>")
      end

      it 'sanitizes the language fields' do
        document = repository.find 'a123'
        expect(document.title).to eq('foo')
        expect(document.description).to eq('hello & goodbye!')
        expect(document.content).to eq('this is html')
      end
    end

    context 'when a created value is provided but not changed' do
      let(:params_without_changed) do
        valid_params.merge(created: DateTime.now, changed: '')
      end

      before { repository.save(params_without_changed) }

      it 'sets "changed" to be the same as "created"' do
       # repository.save(params_without_changed) #REDUNDANT?
        document = repository.find('a123')
        expect(document.changed).to eq document.created
      end
    end
  end
end
