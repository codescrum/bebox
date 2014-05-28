require 'spec_helper'
require_relative 'puppet_spec_helper.rb'
require_relative '../factories/puppet.rb'

describe 'Phase 08: Puppet configure common modules' do

	# let(:puppet) { build(:puppet, :deploy_puppet_user) }
	let(:puppet) { build(:puppet) }

	before(:all) do
	  puppet.configure_common_modules
	end

  after(:all) do
    # puppet.environment.halt_vagrant_nodes
    # puppetenvironment.remove_vagrant_boxes
  end

  context 'nginx module' do
		describe package('nginx') do
		  it { should be_installed }
		end

		describe service('nginx') do
		  it { should be_enabled }
		end

		describe port(3000) do
		  it { should be_listening }
		end
	end

  context 'rbenv module' do
		describe file('/home/pname/.rbenv') do
		  it { should be_directory }
		end
    describe file('/home/pname/.rbenv/versions/1.9.3-p327') do
      it { should be_directory }
    end
	end
end