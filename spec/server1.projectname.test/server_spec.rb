require 'spec_helper'

describe 'vagrant server' do

	let(:builder) { build(:builder) }

	before :all do
	  builder.build_vagrant_nodes
	  builder.up_vagrant_nodes
	end

	describe interface('eth1') do
	  it { should have_ipv4_address("192.168.0.70") }
	end

end