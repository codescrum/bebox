require 'spec_helper'
require 'server_spec'
require 'project_spec'
require 'environment_spec'
require 'server1.pname.test/environment_phase3_spec'
require 'server1.pname.test/environment_phase4_spec'
require 'server1.pname.test/puppet_phase5_spec'
require 'server1.pname.test/puppet_phase6_spec'
require 'server1.pname.test/puppet_phase7_spec'

describe 'Phase 99: ordered specs' do

	RSpec.configure do |config|
		puts 'Configure spec order'
	  config.order_groups_and_examples do |list|
	    list.sort_by { |item| item.description if item.class != RSpec::Core::Example }
	  end
	end

	let(:puppet) { build(:puppet) }

  after(:all) do
    # puppet.environment.halt_vagrant_nodes
    # puppet.environment.remove_vagrant_boxes
  end

	specify("End of tests") {}
end