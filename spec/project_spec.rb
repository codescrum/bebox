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
      subject.create_gemfile
      subject.setup_bundle
      expect(File).to exist("#{subject.path}/Gemfile.lock")
      expect(Dir).to exist("#{subject.path}/.bundle")
    end

    it 'should setup capistrano in project with the configured environments' do
      subject.setup_capistrano
      config_deploy_content = File.read("#{subject.path}/config/deploy.rb").gsub(/\s+/, ' ').strip
      config_deploy_output_content = File.read("spec/fixtures/config_deploy.test").gsub(/\s+/, ' ').strip
      expect(config_deploy_content).to eq(config_deploy_output_content)
      config_deploy_vagrant_content = File.read("#{subject.path}/config/deploy/vagrant.rb").gsub(/\s+/, ' ').strip
      config_deploy_vagrant_output_content = File.read("spec/fixtures/config_deploy_vagrant.test").gsub(/\s+/, ' ').strip
      expect(config_deploy_vagrant_content).to eq(config_deploy_vagrant_output_content)
    end
  end


end