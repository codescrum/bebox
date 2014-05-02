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
    it 'should create local_host.rb template' do
      ############################ RUBY
      expected_content = <<-RUBY
<% self.each do |server| %>

<%= server.ip %>   <%= server.hostname %>
<% end %>
      RUBY
      ############################
      subject.create_directories
      subject.create_local_host_template
      output_file = File.read("#{Dir.pwd }/tmp/config/templates/local_hosts.erb")
      expect(output_file).to eq(expected_content)
    end
  end

  it 'should create Vagrant.rb template' do
    ############################ RUBY
    expected_content = <<-RUBY
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
<% self.each_with_index do |server, index| %>
  config.vm.define :node_<%= index %> do |node|
    node.vm.box = "#{@vagrant_box_base_name}_<%= index %>"
    node.vm.hostname = "<%= server.hostname %>"
    node.vm.network :public_network, :bridge => 'en0: Ethernet', :auto_config => false
    node.vm.provision :shell, :inline => "sudo ifconfig eth1 <%= server.ip] %> netmask 255.255.255.0 up"
  end
<% end %>
end
    RUBY
    ############################
    subject.create_directories
    subject.create_vagrant_template
    output_file = File.read("#{Dir.pwd }/tmp/config/templates/Vagrant.erb")
    expect(output_file).to eq(expected_content)
  end

  it 'should create deploy.rb template' do
    ############################ RUBY
    expected_content =''
    ############################
    subject.create_directories
    subject.create_deploy_file
    output_file = File.read("#{Dir.pwd}/tmp/config/deploy.rb")
    expect(output_file).to eq(expected_content)
  end

  describe 'Add vagrant boxes', :slow do
    before :each do
      @servers = []
      3.times{|i| @servers << Bebox::Server.new(ip:"192.168.200.7#{i}", hostname: "server#{i}.pname.test")}
      @vbox_uri = 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'
      @vagrant_box_base_name = 'test'
    end
    after(:each) do
      3.times{|i| `vagrant box remove test_#{i} virtualbox`}
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
      3.times{|i| @servers << Bebox::Server.new(ip:"192.168.200.7#{i}", hostname: "server#{i}.#{@project_name}.test")}
      subject.create_directories
      ############################ RUBY
      content = <<-EOF
127.0.0.1   localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
      EOF
      ############################

      File::open("#{Dir.pwd}/tmp/hosts", "w")do |f|
        f.write(content)
      end
      subject.create_local_host_template
    end

    it "should add the hosts to the hosts file" do
      ############################ RUBY
      expected_content = <<-EOF
127.0.0.1   localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

192.168.200.70   server0.pname.test
192.168.200.71   server1.pname.test
192.168.200.72   server2.pname.test
      EOF
      ############################
      subject.config_local_hosts_file
      output_file = File.read("#{Dir.pwd }/tmp/hosts")
      expect(output_file.strip).to eq(expected_content.strip)
    end

    it "should not add any hosts into the hosts file" do
      ############################ RUBY
      expected_content = <<-EOF
127.0.0.1   localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
      EOF
      ############################
      subject.servers << Bebox::Server.new(ip:"127.0.0.1", hostname: "localhost")
      subject.config_local_hosts_file
      output_file = File.read("#{Dir.pwd }/tmp/hosts")
      expect(output_file.strip).to eq(expected_content.strip)
    end
  end

  #describe 'Generate Vagranfile' do
  #  before :each do
  #    #subject.create_directories
  #  end
  #
  #  it 'should make a file using the user entries' do
  #
  #  end
  #end
end