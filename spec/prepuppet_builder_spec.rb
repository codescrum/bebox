require 'spec_helper'

describe Bebox::PrepuppetBuilder do

	subject { build(:prepuppet_builder) }

	describe 'Bundle' do
    it 'should create Gemfile in project' do
			subject.builder.create_directories
			subject.create_deploy_file
      expected_content = File.read("templates/Gemfile")
      output_file = File.read("#{subject.new_project_root}/Gemfile")
      expect(output_file).to eq(expected_content)
    end
		it 'should bundle install' do
			subject.builder.create_directories
			subject.setup_bundle
			expect(File).to exist("#{subject.new_project_root}/Gemfile.lock")
			expect(Dir).to exist("#{subject.new_project_root}/.bundle")
		end
	end

	describe 'Capistrano' do
    it 'should setup capistrano in project with the configured stages' do
      subject.builder.build_vagrant_nodes
      subject.builder.up_vagrant_nodes
			subject.setup_bundle
			subject.setup_capistrano
      config_deploy_content = File.read("#{subject.new_project_root}/config/deploy.rb").gsub(/\s+/, ' ').strip
      config_deploy_output_content = File.read("spec/fixtures/config_deploy.test").gsub(/\s+/, ' ').strip
      expect(config_deploy_content).to eq(config_deploy_output_content)
      config_deploy_vagrant_content = File.read("#{subject.new_project_root}/config/deploy/vagrant.rb").gsub(/\s+/, ' ').strip
      config_deploy_vagrant_output_content = File.read("spec/fixtures/config_deploy_vagrant.test").gsub(/\s+/, ' ').strip
      expect(config_deploy_vagrant_content).to eq(config_deploy_vagrant_output_content)
    end
   #  it 'should prepare the boxes' do
   #    subject.builder.build_vagrant_nodes
   #    subject.builder.up_vagrant_nodes
			# subject.setup_bundle
			# subject.setup_capistrano
			# subject.prepare_boxes
  	# end
	end
end
