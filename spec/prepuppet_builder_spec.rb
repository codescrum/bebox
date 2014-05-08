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
end
