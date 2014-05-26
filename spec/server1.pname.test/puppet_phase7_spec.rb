require 'spec_helper'
require_relative 'puppet_spec_helper.rb'
require_relative '../factories/puppet.rb'

describe 'Phase 07: Puppet deploy to user puppet' do

	# let(:puppet) { build(:puppet, :deploy_puppet_user) }
	let(:puppet) { build(:puppet) }

	before(:all) do
	  puppet.deploy
	end

  after(:all) do
    # puppet.environment.halt_vagrant_nodes
    # puppetenvironment.remove_vagrant_boxes
  end

	describe file('/home/puppet/pname/code/shared') do
	  it { should be_directory }
	end

	describe file('/home/puppet/pname/code/releases') do
	  it { should be_directory }
	end

end