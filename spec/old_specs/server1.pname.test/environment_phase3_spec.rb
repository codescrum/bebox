require 'spec_helper'
require_relative 'vagrant_spec_helper.rb'
require_relative '../factories/environment.rb'

describe 'Phase 03: Environment with vagrant up' do

	# let(:environment) { build(:environment, :with_vagrant_up) }
	let(:environment) { build(:environment) }

	before(:all) do
		 environment.up
	end

	describe interface('eth1') do
	  it { should have_ipv4_address(environment.project.servers.first.ip) }
	end

	describe host('server1.pname.test') do
  	it { should be_resolvable }
	end

	describe host('server1.pname.test') do
	  it { should be_reachable }
	  it { should be_reachable.with( :port => 22 ) }
	end

	describe user('vagrant') do
	  it { should exist }
	end

end