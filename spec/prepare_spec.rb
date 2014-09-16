require 'spec_helper'

describe 'Bebox::Node prepare', :fakefs do

  include Bebox::VagrantHelper

  let(:project) { build(:project) }
  let(:nodes) { [ build(:node) ] }
  let(:fixtures_path) { Pathname(__FILE__).dirname.parent + 'spec/fixtures' }

  before :all do
    FakeFS::FileSystem.clone("#{local_hosts_path}/hosts")
    FakeCmd.on!
    FakeCmd.add 'bundle', 0, true
    FakeCmd do
      project.create
      nodes.each{ |node| node.create}
    end
    FakeCmd.off!
  end

  context 'pre vagrant prepare' do
    it 'should regenerate the Vagrantfile' do
      network_interface = RUBY_PLATFORM =~ /darwin/ ? 'en0' : 'eth0'
      Bebox::VagrantHelper.generate_vagrantfile(nodes)
      vagrantfile_content = File.read("#{project.path}/Vagrantfile").gsub(/\s+/, ' ').strip
      output_template = Tilt::ERBTemplate.new("#{fixtures_path}/node/Vagrantfile.test.erb")
      vagrantfile_output_content = output_template.render(nil, ip_address: nodes.first.ip, network_interface: network_interface).gsub(/\s+/, ' ').strip
      expect(vagrantfile_content).to eq(vagrantfile_output_content)
    end
    it 'should regenerate the vagrant deploy file' do
      Bebox::Node.regenerate_deploy_file(project.path, nodes.first.environment, nodes)
      vagrant_deploy_content = File.read("#{project.path}/config/environments/vagrant/deploy.rb").gsub(/\s+/, ' ').strip
      vagrant_deploy_output_content = File.read("#{fixtures_path}/node/vagrant_deploy.test").gsub(/\s+/, ' ').strip
      expect(vagrant_deploy_content).to eq(vagrant_deploy_output_content)
    end
  end

  context 'vagrant prepare' do

    before :all do
      # Fake hosts backup file
      FileUtils.cp "#{local_hosts_path}/hosts", "#{local_hosts_path}/hosts_before_#{project.name}"
      FakeCmd.on!
      FakeCmd.add 'bundle', 0, true
      FakeCmd.add 'echo', 0, true
      FakeCmd.add 'vagrant box list', 0, ''
      FakeCmd.add 'vagrant box add', 0, true
      FakeCmd do
        prepare_vagrant(nodes.first)
      end
      FakeCmd.off!
    end

    describe 'Configure the hosts file' do
      it 'should create a hosts backup file' do
        hosts_backup_file = "#{nodes.first.local_hosts_path}/hosts_before_#{project.name}"
        original_hosts_content = File.read("#{nodes.first.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
        expect(File).to exist(hosts_backup_file)
        hosts_backup_content = File.read(hosts_backup_file).gsub(/\s+/, ' ').strip
        expect(original_hosts_content).to eq(hosts_backup_content)
      end

      it 'should add the hosts config to hosts file' do
        node = nodes.first
        # Fake generated hosts file
        template = Tilt::ERBTemplate.new("#{fixtures_path}/node/hosts.test.erb")
        hosts_content = template.render(nil, node: node).gsub(/\s+/, ' ').strip
        expect(hosts_content).to include(*nodes.map{|node| "#{node.ip} #{node.hostname}"})
      end
    end

    describe 'vagrant setup' do
      it 'should add the node to vagrant' do
        vagrant_box_names_expected = nodes.map{|node| "#{project.name}-#{node.hostname}"}
        node = nodes.first
        # Fake installed_vagrant_box_names
        FakeCmd.clear!
        FakeCmd.on!
        FakeCmd.add 'vagrant box list', 0, "#{project.name}-#{node.hostname}"
        expect(installed_vagrant_box_names(node)).to include(*vagrant_box_names_expected)
        FakeCmd.off!
      end

      it 'should up the vagrant boxes' do
        # Stub vagrant up
        Bebox::VagrantHelper.stub(:exec) { 0 }
        Bebox::VagrantHelper.stub(:fork) { 0 }
        Process.stub(:wait) { true }
        Bebox::VagrantHelper.up_vagrant_nodes(project.path)
        # Fake vagrant_box_running?
        FakeCmd.on!
        FakeCmd.add 'vagrant status', 0, "#{nodes.first.hostname} running"
        nodes.each{|node| expect(vagrant_box_running?(node)).to eq(true)}
        FakeCmd.off!
      end

      it 'should connect to vagrant box through ssh' do
        connection_successful = true
        FakeCmd.on!
        FakeCmd.add 'ssh', 0, true
        nodes.each{|node| expect(vagrant_box_running?(node)).to eq(true)}
        nodes.each do |node|
          `ssh -q -oStrictHostKeyChecking=no -i ~/.vagrant.d/insecure_private_key -l vagrant #{node.ip} exit`
          connection_successful &= ($?.exitstatus == 0)
        end
        expect(connection_successful).to eq(true)
        FakeCmd.off!
      end
    end

    describe 'prepare machine' do
      before :all do
        FakeCmd.clear!
        FakeCmd.on!
        FakeCmd.add 'bundle', 0, true
        FakeCmd do
          nodes.first.prepare
        end
        FakeCmd.off!
      end

      it 'creates a checkpoint' do
        node = nodes.first
        node_checkpoint_path = "#{node.project_root}/.checkpoints/environments/#{node.environment}/phases/phase-1/#{node.hostname}.yml"
        expect(File.exist?(node_checkpoint_path)).to be (true)
        prepared_node_content = File.read(node_checkpoint_path).gsub(/\s+/, ' ').strip
        ouput_template = Tilt::ERBTemplate.new("#{fixtures_path}/node/prepared_node_0.test.erb")
        prepared_node_expected_content = ouput_template.render(nil, node: node).gsub(/\s+/, ' ').strip
        expect(prepared_node_content).to eq(prepared_node_expected_content)
      end
    end
  end

  context 'destroy machine' do

    before :all do
      # Fake hosts backup file
      FileUtils.cp "#{local_hosts_path}/hosts", "#{local_hosts_path}/hosts_before_#{project.name}"
      FakeCmd.clear!
      node = nodes.first
      FakeCmd.on!
      FakeCmd.add 'vagrant box list', 0, ""
      FakeCmd.add 'vagrant halt', 0, true
      FakeCmd.add 'vagrant destroy', 0, true
      FakeCmd.add 'vagrant box remove', 0, true
      FakeCmd.add 'vagrant status', 0, ''
      FakeCmd do
        Bebox::VagrantHelper.halt_vagrant_nodes(node.project_root)
        remove_vagrant_box(node)
      end
    end

    after :all do
      FakeCmd.off!
    end

    it 'checks that vagrant box not be running' do
      FakeCmd do
        expect(vagrant_box_running?(nodes.first)).to be(false)
      end
    end

    it 'checks that vagrant box not exist' do
      FakeCmd do
        expect(vagrant_box_exist?(nodes.first)).to be(false)
      end
    end

    it 'restores the local hosts file' do
      hosts_backup_content = File.read("#{local_hosts_path}/hosts_before_#{project.name}").gsub(/\s+/, ' ').strip
      nodes.first.restore_local_hosts(project.name)
      hosts_content = File.read("#{local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
      expect(hosts_content).to eq(hosts_backup_content)
      expect(File.exist?("#{local_hosts_path}/hosts_before_#{project.name}")).to be(false)
    end
  end
end