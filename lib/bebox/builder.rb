require 'tilt'
#require 'capistrano'
require "bebox/server"
module Bebox
  class Builder
    attr_accessor :project_name, :servers, :vbox_uri, :vagrant_box_base_name, :vagrant_box_provider, :current_pwd, :new_project_root, :local_hosts_file_location

    def initialize(project_name, servers, vbox_uri, vagrant_box_base_name, current_pwd = Dir.pwd, vagrant_box_provider = 'virtualbox')
      @current_pwd = current_pwd
      @project_name = project_name
      @servers = servers
      @vbox_uri= vbox_uri
      @vagrant_box_base_name = vagrant_box_base_name
      @vagrant_box_provider = vagrant_box_provider
      create_project_directory
      if  ENV['RUBY_ENV'].eql? 'test'
        @local_hosts_file_location = "#{@current_pwd}"
      else
        @local_hosts_file_location = RUBY_PLATFORM =~ /darwin/ ? '/private/etc' : '/etc'
      end
    end

    def vagrant_box_filename
      @vbox_uri.split('/').last
    end

    def build_vagrant_nodes
      create_directories
      create_files
    end

    def create_project_directory
      `cd #{@current_pwd} && mkdir -p #{@project_name}`
      @new_project_root = "#{@current_pwd}/#{@project_name}"
    end

    def create_directories
      `cd #{@new_project_root} && mkdir -p config && mkdir -p config/deploy && mkdir -p config/templates`
    end

    def create_files
      create_templates
      create_deploy_file
      add_vagrant_boxes
      generate_vagrantfile
    end

    # Generate the vagrantfile take into account the settings into vagrant hiera file
    def generate_vagrantfile
      template = Tilt::ERBTemplate.new("#{@new_project_root}/config/templates/Vagrant.erb")
      File.open("#{@new_project_root}/Vagrantfile", 'w') do |f|
        f.write template.render(@servers)
      end
    end

    # Add the specified boxes and init vagrant to create Vagrantfile
    def add_vagrant_boxes
      already_installed_boxes = installed_vagrant_box_names

      @servers.each_with_index do |server, index|
        box_name = "#{@vagrant_box_base_name}_#{index}"
        puts "  Adding server: #{server.hostname}..."
        `vagrant box add #{box_name} #{vagrant_box_filename}` unless already_installed_boxes.include? box_name
      end
    end


    # creates
    def create_deploy_file
      content = ''
      File::open("#{@new_project_root}/config/deploy.rb", "w")do |f|
        f.write(content)
      end
    end

    # creates a template
    def create_templates
      create_local_host_template
      create_vagrant_template
    end

    # creates a template
    def create_local_host_template
      content = <<-RUBY
<% self.each do |server| %>

<%= server.ip %>   <%= server.hostname %>
<% end %>
      RUBY
      File::open("#{@new_project_root}/config/templates/local_hosts.erb", "w")do |f|
        f.write(content)
      end
    end

    # creates a template
    def create_vagrant_template
      content =<<-RUBY
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
<% self.each_with_index do |server, index| %>
  config.vm.define :node_<%= index %> do |node|
    node.vm.box = "#{@vagrant_box_base_name}_<%= index %>"
    node.vm.hostname = "<%= server.hostname %>"
    node.vm.network :public_network, :bridge => 'en0: Ethernet', :auto_config => false
    node.vm.provision :shell, :inline => "sudo ifconfig eth1 <%= server.ip %> netmask 255.255.255.0 up"
  end
<% end %>
end
      RUBY
      File::open("#{@new_project_root}/config/templates/Vagrant.erb", "w")do |f|
        f.write(content)
      end
    end

    # Modify the local hosts file
    def config_local_hosts_file
      template = Tilt::ERBTemplate.new("#{@new_project_root}/config/templates/local_hosts.erb")
      nameservers = template.render(@servers)
      is_hosts_configured = true

      nameservers.each_line.with_index do |hostname, index|
        unless index==0
          is_hosts_configured &= (`if grep -q '#{hostname}' '#{@local_hosts_file_location}/hosts'; then echo 'true'; else echo 'false'; fi`).strip == 'true'
        end
      end

      puts is_hosts_configured

      if is_hosts_configured
        puts 'the server file is already configured'
      else
        puts 'Configuring hosts file'
        `sudo cp #{@local_hosts_file_location}/hosts #{@local_hosts_file_location}/hosts_.test`
        `sudo chmod 777 #{@local_hosts_file_location}/hosts_.test`
        # Write the template
        File.open("#{@local_hosts_file_location}/hosts_.test", 'a') {|f| f.write nameservers}
        `sudo mv #{@local_hosts_file_location}/hosts_.test #{@local_hosts_file_location}/hosts`
      end
    end

    # return an Array with the names of the currently installed vagrant boxes
    # @returns Array
    def installed_vagrant_box_names
      (`vagrant box list`).split("\n").map{|vagrant_box| vagrant_box.split(' ').first}
    end
  end
end