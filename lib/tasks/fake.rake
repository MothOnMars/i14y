namespace :fake do
  desc "Creates a specified number of test documents for an existing collection"
  # Sample usage, to create 10 documents for the collection with handle 'my_drawer':
  # rake fake:documents[my_drawer,10]

  task :documents, [:index_name, :document_count] => [:environment] do |_t, args|
    #Document.index_name = Document.index_namespace(args[:index_name])
    index_name = DocumentRepository.index_namespace(args[:index_name])
    document_repository = DocumentRepository.new(index_name: index_name)
    document_repository.create_index!
    count = args[:document_count].to_i

    count.times { document_repository.save(Document.new(fake_doc)) }
    document_repository.refresh_index!
  end

  private

  def fake_doc
    { id: Time.now.to_f.to_s,
      title: Faker::TvShows::TwinPeaks.character,
      path: fake_url,
      created: [Faker::Time.between(3.years.ago, Date.today).to_json, nil].sample,
      description:  [nil, Faker::TvShows::TwinPeaks.location].sample,
      content: quotes,
      promote: [true,false].sample,
      language: 'en',
      tags: %w(trees coffee pie).sample([1,2,3].sample).join(',')
    }
  end

  def fake_url
    domain = [[nil,'www','coffee','pie'].sample, 'twinpeaks.gov'].compact.join('.')
    directories = [%w(plastic fish mill).sample, %w(gum whittling fire).sample].join('/')
    file = Faker::TvShows::TwinPeaks.location.parameterize
    filetype = %w(html doc pdf).sample
    protocol = %w(http https).sample
    "#{protocol}://#{domain}/#{directories}/#{file}.#{filetype}"
  end

  def quotes
    quotes = ''
    10.times { quotes << Faker::TvShows::TwinPeaks.quote + ' ' }
    quotes
  end
end
