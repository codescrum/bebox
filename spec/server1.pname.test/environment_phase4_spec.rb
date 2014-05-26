require 'spec_helper'
require_relative 'vagrant_spec_helper.rb'
require_relative '../factories/environment.rb'

describe 'Phase 04: Environment with common dev installed and initial hiera for users configured' do

	# let(:environment) { build(:environment, :with_common_dev) }
	let(:environment) { build(:environment) }

	before(:all) do
  	environment.install_common_dev
	end

	describe command('hostname') do
		it 'should configure the hostname' do
			should return_stdout environment.project.servers.first.hostname
		end
	end

	describe command("dpkg -s #{Bebox::Environment::UBUNTU_DEPENDENCIES.join(' ')} | grep Status") do
		it 'should install ubuntu dependencies' do
			should return_stdout /(Status: install ok installed\s*){#{Bebox::Environment::UBUNTU_DEPENDENCIES.size}}/
		end
	end

	describe file('/home/vagrant/pname/code/current/initial_puppet/hiera/hiera.yaml') do
	  it { should be_file }
	  its(:content) {
			hiera_content = File.read("spec/fixtures/hiera.yaml.test")
	  	should == hiera_content
	  }
	end

	describe file('/home/vagrant/pname/code/current/initial_puppet/hiera/data/common.yaml') do
	  it { should be_file }
	end

end