require 'spec_helper'

describe 'capistrano prepare vagrant prepuppet' do

	let(:prepuppet_builder) { build(:prepuppet_builder) }

	before :all do
	  prepuppet_builder.builder.build_vagrant_nodes
	  prepuppet_builder.builder.up_vagrant_nodes
		prepuppet_builder.setup_bundle
		prepuppet_builder.setup_capistrano
		prepuppet_builder.prepare_boxes
	end

	describe package('curl') do
		it { should be_installed }
	end

	describe command('hostname') do
		it 'should configure the hostname' do
			should return_stdout 'server1.projectname.test'
		end
	end

	describe command("dpkg -s #{Bebox::PrepuppetBuilder::UBUNTU_DEPENDENCIES.join(' ')} | grep Status") do
		it 'should install ubuntu dependencies' do
			should return_stdout /(Status: install ok installed\s*){#{Bebox::PrepuppetBuilder::UBUNTU_DEPENDENCIES.size}}/
		end
	end

end