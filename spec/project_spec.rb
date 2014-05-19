require 'spec_helper'

describe Bebox::Project do

  describe 'Project creation' do

    subject { build(:project) }

    it 'should create the project directory' do
      subject.create_project_directory
      expect(Dir.exist?(subject.path)).to be true
    end

    it 'should create the project subdirectories' do
      directories_expected = ['config', 'deploy']
      subject.create_subdirectories
      directories = []
      directories << Dir["#{subject.path}/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/*/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.path}/*/*/*/"].map { |f| File.basename(f) }
      expect(directories.flatten).to include(*directories_expected)
    end
  end

  describe 'Project dependency installation' do

    subject { build(:project, :created) }

    it 'should create Gemfile in project' do
      subject.create_gemfile
      expected_content = File.read("templates/Gemfile")
      output_file = File.read("#{subject.path}/Gemfile")
      expect(output_file).to eq(expected_content)
    end
    it 'should install dependencies' do
      subject.setup_bundle
      expect(File).to exist("#{subject.path}/Gemfile.lock")
      expect(Dir).to exist("#{subject.path}/.bundle")
    end
  end
end