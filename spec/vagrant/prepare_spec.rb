require 'spec_helper'

describe 'Test 01: Prepares a bebox project with one vagrant node', :vagrant do

  include Bebox::VagrantHelper

  let(:project) { build(:project) }
  let(:node) { build(:node, ip: YAML.load_file("#{Dir.pwd}/spec/vagrant/support/config_specs.yaml")['test_ip']) }

  before :all do
    # Create a tmp directory inside project
    `mkdir -p #{Dir.pwd}/tmp`
    # Clean the tmp directory of a test project
    `rm -rf #{Dir.pwd}/tmp/#{project.name}`
  end

  context '00: project creation' do
    before :all do
      project.create
    end

    it 'install project dependencies' do
      expect(File).to exist("#{project.path}/Gemfile.lock")
    end
  end

  context '01: node creation' do
    before :all do
      node.create
    end

    it 'checks that node ip is free' do
      expect(Bebox::NodeWizard.new.free_ip?(node.ip)).to eq(true)
    end
  end

  context '02: vagrant machine creation' do

    let (:original_hosts_content) { File.read("#{node.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip }

    before :all do
      puts "\nPlease provide your local password, if asked, to configure the local hosts file.".yellow
      original_hosts_content
      # Re-generate vagrantfile and deploy file
      Bebox::VagrantHelper.generate_vagrantfile([node])
      Bebox::Node.regenerate_deploy_file(project.path, 'vagrant', [node])
      # Create and Up the vagrant machine
      `sudo rm -rf #{node.local_hosts_path}/hosts_before_#{project.name}`
      prepare_vagrant(node)
      Bebox::VagrantHelper.up_vagrant_nodes(project.path)
    end

    describe 'Configure the hosts file' do
      it 'should create a hosts backup file' do
        hosts_backup_file = "#{node.local_hosts_path}/hosts_before_#{project.name}"
        expect(File).to exist(hosts_backup_file)
        hosts_backup_content = File.read(hosts_backup_file).gsub(/\s+/, ' ').strip
        expect(original_hosts_content).to eq(hosts_backup_content)
      end

      it 'should add the hosts config to hosts file' do
        hosts_content = File.read("#{node.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
        expect(hosts_content).to include("#{node.ip} #{node.hostname}")
      end
    end

    describe 'vagrant setup' do
      it 'should add the node to vagrant' do
        vagrant_box_name_expected = "#{project.name}-#{node.hostname}"
        expect(installed_vagrant_box_names(node)).to include(vagrant_box_name_expected)
      end

      it 'should up the vagrant boxes' do
        expect(vagrant_box_running?(node)).to eq(true)
      end

      it 'should connect to vagrant box through ssh' do
        `ssh -q -oStrictHostKeyChecking=no -i ~/.vagrant.d/insecure_private_key -l vagrant #{node.ip} exit`
        expect($?.exitstatus).to eq(0)
      end
    end
  end
end