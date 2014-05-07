require 'spec_helper'

describe Bebox::Builder do

  subject{Bebox::Builder.new(@project_name, @servers, @vbox_uri, @vagrant_box_base_name, "#{Dir.pwd}/tmp", 'virtualbox')}

  describe 'Folder' do

    it 'should create the directories' do
      directories_expected = ['config', 'deploy', 'templates']
      subject.create_directories
      directories = []
      directories << Dir["#{subject.new_project_root}/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.new_project_root}/*/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.new_project_root}/*/*/*/"].map { |f| File.basename(f) }
      expect(directories.flatten).to include(*directories_expected)
    end
  end
  describe 'Files' do
    it 'should create local_hosts.erb template' do
      expected_content = File.read("templates/local_hosts.erb")
      subject.create_directories
      subject.create_local_host_template
      output_file = File.read("#{Dir.pwd }/tmp/config/templates/local_hosts.erb")
      expect(output_file).to eq(expected_content)
    end
  end

  it 'should create Vagrantfile.erb template' do
    expected_content = File.read("templates/Vagrantfile.erb")
    subject.create_directories
    subject.create_vagrant_template
    output_file = File.read("#{Dir.pwd }/tmp/config/templates/Vagrantfile.erb")
    expect(output_file).to eq(expected_content)
  end

  it 'should create deploy.rb template' do
    expected_content =''
    subject.create_directories
    subject.create_deploy_file
    output_file = File.read("#{Dir.pwd}/tmp/config/deploy.rb")
    expect(output_file).to eq(expected_content)
  end

  describe 'Add vagrant boxes', :slow do
    before :each do
      @servers = []
      3.times{|i| @servers << Bebox::Server.new(ip:"192.168.0.7#{i}", hostname: "server#{i}.pname.test")}
      @vbox_uri = 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'
      @vagrant_box_base_name = 'test'
    end
    after(:each) do
      subject.remove_vagrant_boxes
    end

    it 'should be add 3 vagrant boxes' do
      vagrant_box_names_expected = ['test_0','test_1','test_2']
      subject.add_vagrant_boxes
      expect(subject.installed_vagrant_box_names).to include(*vagrant_box_names_expected)
    end
  end

  describe 'Modify the hosts file' do
    before :each do
      @project_name = 'pname'
      @servers = []
      3.times{|i| @servers << Bebox::Server.new(ip:"192.168.0.7#{i}", hostname: "server#{i}.#{@project_name}.test")}
      subject.create_directories
      subject.create_local_host_template
      `cp spec/fixtures/hosts.test tmp/hosts`
    end

    it 'should add the hosts config to hosts file' do
      subject.config_local_hosts_file
      expect(File).to exist("#{Dir.pwd }/tmp/hosts")
      hosts_content = File.read("#{Dir.pwd }/tmp/hosts").gsub(/\s+/, ' ').strip
      expect(hosts_content).to include(*@servers.map{|server| "#{server.ip} #{server.hostname}"})
    end

    it 'should create a hosts backup file' do
      hosts_backup_file = subject.config_local_hosts_file
      expect(File).to exist(hosts_backup_file)
      original_hosts_content = File.read("spec/fixtures/hosts.test").gsub(/\s+/, ' ').strip
      hosts_backup_content = File.read(hosts_backup_file).gsub(/\s+/, ' ').strip
      expect(original_hosts_content).to eq(hosts_backup_content)
    end
  end

  describe 'Generate Vagrantfile' do
    before :each do
      @vbox_uri = 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'
      @vagrant_box_base_name  ='test'
      @project_name = 'pname'
      @servers = []
      1.times{|i| @servers << Bebox::Server.new(ip:"192.168.0.7#{i}", hostname: "server#{i}.#{@project_name}.test")}
      subject.create_directories
    end

    it 'should create a Vagrantfile using the user entries' do
      subject.create_vagrant_template
      subject.generate_vagrantfile
      expect(File).to exist("#{subject.new_project_root}/Vagrantfile")
      output_file = File.read("#{subject.new_project_root}/Vagrantfile").gsub(/\s+/, ' ').strip
      output_file_test = File.read("spec/fixtures/Vagrantfile.test").gsub(/\s+/, ' ').strip
      expect(output_file).to eq(output_file_test)
    end
  end

  describe 'Vagrant boxes up', :slow do
    before :each do
      @vbox_uri = 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'
      @vagrant_box_base_name  ='test'
      @project_name = 'pname'
      @servers = []
      1.times{|i| @servers << Bebox::Server.new(ip:"192.168.0.7#{i}", hostname: "server#{i}.#{@project_name}.test")}
      subject.build_vagrant_nodes
      subject.up_vagrant_nodes
    end
    after :each do
      # halt and remove vagrant boxes
      subject.halt_vagrant_nodes
      subject.remove_vagrant_boxes
    end
    it 'should up the vagrant boxes' do
      vagrant_status = subject.vagrant_nodes_status
      nodes_running = true
      @servers.size.times{|i| nodes_running &= (vagrant_status =~ /node_#{i}\s+running/)}
      expect(nodes_running).to eq(true)
    end
    it 'should connect to config boxes through ssh' do
      connection_successful = true
      @servers.each do |server|
        `ssh -q -oStrictHostKeyChecking=no -i ~/.vagrant.d/insecure_private_key -l vagrant #{server.ip} exit`
        connection_successful &= ($?.exitstatus == 0)
      end
      expect(connection_successful).to eq(true)
    end
  end
end