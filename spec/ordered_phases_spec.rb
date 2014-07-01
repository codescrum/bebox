require 'spec_helper'
require 'project_wizard_spec'
require 'project_spec'
require 'environment_wizard_spec'
require 'environment_spec'
require 'node_wizard_spec'
require 'node_spec'
require 'prepare_spec'
require 'node0.server1.test/prepare_phase_spec'
require 'node0.server1.test/puppet_step_0_spec'
require 'node0.server1.test/puppet_step_1_spec'
require 'role_spec'
require 'profile_spec'
require 'role_profiles_spec'
require 'node_role_spec'

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