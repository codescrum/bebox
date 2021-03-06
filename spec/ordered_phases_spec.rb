require 'spec_helper'
require 'cli_spec'
require 'wizards/project_wizard_spec'
require 'wizards/environment_wizard_spec'
require 'wizards/node_wizard_spec'
require 'wizards/role_wizard_spec'
require 'wizards/profile_wizard_spec'
require 'wizards/provision_wizard_spec'
require 'project_spec'
require 'environment_spec'
require 'node_spec'
require 'pre_prepare_spec'
require 'node0.server1.test/prepare_phase_spec'
require 'role_spec'
require 'profile_spec'
require 'role_profiles_spec'
require 'node_role_spec'
require 'pre_provision_steps_spec'
require 'node0.server1.test/provision_step_0_spec'
require 'node0.server1.test/provision_step_1_spec'
require 'node0.server1.test/provision_step_2_spec'
require 'node0.server1.test/provision_step_3_spec'


describe 'Test 99: ordered specs' do

  RSpec.configure do |config|
    puts 'Configure spec order'
    config.order_groups_and_examples do |list|
      list.sort_by { |item| item.description if item.class != RSpec::Core::Example }
    end
  end

  context '99: project destroy' do

    include Bebox::VagrantHelper

    let(:project) { build(:project) }
    let(:node) { build(:node) }

    it 'should clean spec files' do
      # Test if the vagrant was halt
      Bebox::VagrantHelper.halt_vagrant_nodes(node.project_root)
      expect(vagrant_box_running?(node)).to be(false)
      # Test if the vagrant box was destroyed
      remove_vagrant_box(node)
      expect(vagrant_box_exist?(node)).to be(false)
      # Test if the project directory was destroyed
      project.destroy
      expect(Dir.exist?("#{project.path}")).to be(false)
      # Test that the local hosts file was restored
      puts "\nPlease provide your local password, if asked, to configure the local hosts file.".yellow
      hosts_backup_content = File.read("#{node.local_hosts_path}/hosts_before_#{project.name}").gsub(/\s+/, ' ').strip
      node.restore_local_hosts(project.name)
      hosts_content = File.read("#{node.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
      expect(hosts_content).to eq(hosts_backup_content)
      expect(File.exist?("#{node.local_hosts_path}/hosts_before_#{project.name}")).to be(false)
    end
  end

  specify("End of tests") {}
end