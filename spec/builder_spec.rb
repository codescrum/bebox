require 'spec_helper'

describe Bebox::Builder do

  subject{Bebox::Builder.new(@servers, @vbox_uri, @vagrant_box_base_name, "#{Dir.pwd }/tmp")}

  context 'Folder' do

    it 'should create the directories' do
      directories_expected = ['config', 'deploy', 'templates']
      subject.create_directories
      directories = []
      directories << Dir["#{subject.new_project_root}/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.new_project_root}/*/*/"].map { |f| File.basename(f) }
      expect(directories.flatten).to include(*directories_expected)
    end
  end
  context 'Files' do
    it 'should create local_host.rb template' do
      ############################ RUBY
      content_expected = <<-RUBY
<% self.each do |server| %>

<%= server.ip %>   <%= server.hostname %>
<% end %>
      RUBY
      ############################
      subject.create_directories
      subject.create_local_host_template
      output_file = File.read("#{Dir.pwd }/tmp/config/templates/local_hosts.erb")
      expect(output_file).to eq(content_expected)
    end
  end

  it 'should create Vagrant.rb template' do
    ############################ RUBY
    content_expected = <<-RUBY
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
    expect(output_file).to eq(content_expected)
  end

  it 'should create deploy.rb template' do
    ############################ RUBY
    content_expected =''
    ############################
    subject.create_directories
    subject.create_deploy_file
    output_file = File.read("#{Dir.pwd }/tmp/config/deploy.rb")
    expect(output_file).to eq(content_expected)
  end

  context 'Add vagrant boxes', :slow do
    before :each do
      @servers = []
      3.times{|i| @servers << Bebox::Server.new(ip:"192.168.200.7#{i}", hostname: "server#{i}.pname.test")}
      @vbox_uri = 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'
      @vagrant_box_base_name = 'test'
    end
    it 'should be add 3 vagrant boxes' do
      vagrant_box_names_expected = ['test_0','test_1','test_2']
      subject.add_vagrant_boxes
      expect(subject.installed_vagrant_box_names).to include(*vagrant_box_names_expected)
    end
  end
end