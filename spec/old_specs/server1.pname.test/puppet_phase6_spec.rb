require 'spec_helper'
require_relative 'vagrant_spec_helper.rb'
require_relative '../factories/puppet.rb'

describe 'Phase 06: Puppet apply users module' do

	# let(:puppet) { build(:puppet, :apply_users) }
	let(:puppet) { build(:puppet) }

	before(:all) do
		puppet.apply_users
	end

	describe user('puppet') do
	  it { should exist }
	  it { should belong_to_group 'root' }
		it { should have_home_directory '/home/puppet' }
		it { should have_login_shell '/bin/bash' }
		it { should have_uid 7000 }
	end

	describe user('pname') do
	  it { should exist }
	  it { should belong_to_group 'root' }
	  it { should have_home_directory '/home/pname' }
	  it { should have_login_shell '/bin/bash' }
	  it { should have_uid 7001 }
	end

	describe file('/home/puppet/.ssh/authorized_keys') do
		let(:disable_sudo) { false }
	  it { should be_file }
	  its(:content) {
			keys_content = File.read("#{puppet.environment.project.path}/keys/puppet.rsa.pub").strip
	  	should == "#{keys_content} "
	  }
	end

	describe file('/etc/sudoers.d/10_puppet') do
		let(:disable_sudo) { false }
	  it { should be_file }
	end
end