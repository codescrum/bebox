require 'spec_helper'

describe Bebox::Builder do

  subject{Bebox::Builder.new(@servers, @vbox_uri, @vagrant_box_base_name, "#{Dir.pwd }/tmp")}

  context 'folder' do

    it 'should create the directories' do
      directories_expected = ['config', 'deploy', 'templates']
      subject.create_directories
      directories = []
      directories << Dir["#{subject.new_project_root}/*/"].map { |f| File.basename(f) }
      directories << Dir["#{subject.new_project_root}/*/*/"].map { |f| File.basename(f) }
      expect(directories.flatten).to include(*directories_expected)
    end
  end
  context 'files' do
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
end