require 'spec_helper'
require 'project_wizard_spec'
require 'project_spec'
require 'environment_spec'
require 'node_wizard_spec'
require 'node_spec'
require 'prepare_spec'
require 'node0.server1.test/prepare_phase_spec'
require 'role_spec'
require 'profile_spec'
require 'role_profiles_spec'
require 'node_role_spec'
require 'puppet_pre_steps_spec'
require 'node0.server1.test/puppet_step_0_spec'
require 'node0.server1.test/puppet_step_1_spec'
require 'node0.server1.test/puppet_step_2_spec'
require 'node0.server1.test/puppet_step_3_spec'


describe 'Test 99: ordered specs' do

  RSpec.configure do |config|
    puts 'Configure spec order'
    config.order_groups_and_examples do |list|
      list.sort_by { |item| item.description if item.class != RSpec::Core::Example }
    end
  end

  context '99: project destroy' do

    let(:project) { build(:project) }
    let(:node) { build(:node) }

    it 'should clean spec files' do
      # Test if the vagrant was halt
      Bebox::Node.halt_vagrant_nodes(node.project_root)
      expect(node.vagrant_box_running?).to be(false)
      # Test if the vagrant box was destroyed
      node.remove_vagrant_box
      expect(node.vagrant_box_exist?).to be(false)
      # Test if the project directory was destroyed
      project.destroy
      expect(Dir.exist?("#{project.path}")).to be(false)
      # Test that the local hosts file was restored
      puts "\nPlease provide your account password, if ask you, to restore the local hosts file.".yellow
      hosts_backup_content = File.read("#{node.local_hosts_path}/hosts_before_bebox_#{project.name}").gsub(/\s+/, ' ').strip
      node.restore_local_hosts(project.name)
      hosts_content = File.read("#{node.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
      expect(hosts_content).to eq(hosts_backup_content)
      expect(File.exist?("#{node.local_hosts_path}/hosts_before_bebox_#{project.name}")).to be(false)
    end
  end

  specify("End of tests") {}
end