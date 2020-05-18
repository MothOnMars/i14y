require 'rails_helper'
require 'rake'

describe 'i14y tasks' do
  describe 'reindex' do
    let(:task_name) { 'i14y:reindex' }

    before(:all) do
      Rake.application = Rake::Application.new
      Rake.application.rake_require('tasks/i14y')
      Rake::Task.define_task(:environment)
    end

    context 'when indices exist' do
      binding.pry
    end
    xit 'generates the required number of documents' do
      expect(Document).to receive(:create).exactly(3).times
      Rake::Task['fake:documents'].invoke('my_drawer','3')
    end
  end
end
