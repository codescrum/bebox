require 'spec_helper'
require 'vagrant/prepare_spec'
require 'vagrant/node0.server1.test/phase-1_prepare_spec'
require 'vagrant/node0.server1.test/phase-2_step-0_provision_spec'
require 'vagrant/node0.server1.test/phase-2_step-1_provision_spec'
require 'vagrant/node0.server1.test/phase-2_step-2_provision_spec'
require 'vagrant/node0.server1.test/phase-2_step-3_provision_spec'


describe 'Test 99: ordered specs', :vagrant do

  RSpec.configure do |config|
    puts 'Configure spec order'
    config.order_groups_and_examples do |list|
      list.sort_by { |item| item.description if item.class != RSpec::Core::Example }
    end
  end

  context '99: project destroy' do

    include Bebox::VagrantHelper

    RSpec.configure do |config|
      config.before do
        config.host = 'node0.server1.test'
      end
    end

    let(:project) { build(:project) }
    let(:node) { build(:node, ip: YAML.load_file("#{Dir.pwd}/spec/vagrant/support/config_specs.yaml")['test_ip']) }

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
end