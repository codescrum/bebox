require 'spec_helper'

describe Bebox::Environment do

	subject { build(:environment) }

  describe 'Run vagrant boxes for the environment', :slow do

    after(:all) do
      subject.halt_vagrant_nodes
      subject.remove_vagrant_boxes
    end

    describe 'Configure the hosts file' do
      after(:each) do
        subject.restore_local_hosts
      end

      it 'should add the hosts config to hosts file' do
        subject.configure_local_hosts
        hosts_content = File.read("#{subject.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
        expect(hosts_content).to include(*subject.servers.map{|server| "#{server.ip} #{server.hostname}"})
      end

      it 'should create a hosts backup file' do
        original_hosts_content = File.read("#{subject.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
        subject.configure_local_hosts
        expect(File).to exist(subject.hosts_backup_file)
        hosts_backup_content = File.read(subject.hosts_backup_file).gsub(/\s+/, ' ').strip
        expect(original_hosts_content).to eq(hosts_backup_content)
      end
    end

    it 'should create Vagrantfile' do
      subject.generate_vagrantfile
      output_file = File.read("#{subject.project_path}/Vagrantfile").gsub(/\s+/, ' ').strip
      output_file_test = File.read("spec/fixtures/Vagrantfile.test").gsub(/\s+/, ' ').strip
      expect(output_file).to eq(output_file_test)
    end

    it 'should add the boxes to vagrant' do
      vagrant_box_names_expected = ['test_0']
      subject.generate_vagrantfile
      subject.add_vagrant_boxes
      expect(subject.installed_vagrant_box_names).to include(*vagrant_box_names_expected)
    end

    it 'should up the vagrant boxes' do
      subject.up
      vagrant_status = subject.vagrant_nodes_status
      nodes_running = true
      subject.servers.size.times{|i| nodes_running &= (vagrant_status =~ /node_#{i}\s+running/)}
      expect(nodes_running).to eq(true)
    end

    it 'should connect to config boxes through ssh' do
      connection_successful = true
      subject.servers.each do |server|
        `ssh -q -oStrictHostKeyChecking=no -i ~/.vagrant.d/insecure_private_key -l vagrant #{server.ip} exit`
        connection_successful &= ($?.exitstatus == 0)
      end
      expect(connection_successful).to eq(true)
    end
  end

end
