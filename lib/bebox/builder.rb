require 'tilt'
#require 'capistrano'
require "#{@new_project_folder}/lib/bebox/server"

class Builder
  attr_accessor :servers, :vbox_uri, :vagrant_box_base_name, :new_project_folder, :local_hosts_file_location

  def initialize(servers, vbox_uri,vagrant_box_base_name, new_project_folder = @new_project_folder )
    @servers = servers
    @vbox_uri= vbox_uri
    @vagrant_box_base_name = vagrant_box_base_name
    @new_project_folder = new_project_folder
    if ENV['test']
      @local_hosts_file_location =   "#{@new_project_folder}/tmp"
    else
      @local_hosts_file_location =   RUBY_PLATFORM =~ /darwin/ ? '/private/etc' : '/etc'
    end
  end
  def build_vagrant_nodes
    create_folders
    create_files
  end

  def create_folders
    `mkdir config && mkdir config/deploy && mkdir config/templates`
  end

  def create_files
    create_templates
    create_deploy_file
    add_vagrant_boxes
    generate_vagrantfile
  end

  # Generate the vagrantfile take into account the settings into vagrant hiera file
  def generate_vagrantfile
    template = Tilt::ERBTemplate.new("#{@new_project_folder}/config/templates/Vagrantfile.erb")
    File.open("#{@new_project_folder}/Vagrantfile", 'w') do |f|
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


  def create_deploy_file
    content = ''
    File::open("#{@new_project_folder}/config/deploy.rb", "w")do |f|
      f.write(content)
    end
  end

  def create_templates
    create_local_host_template
    create_vagrant_template
  end

  def create_local_host_template
    content = <<-RUBY
<% self.each do |server| %>

<%= server.ip %>   <%= server.hostname %>
<% end %>
    RUBY
    File::open("#{@new_project_folder}/config/templates/local_hosts.erb", "w")do |f|
      f.write(content)
    end
  end

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
    node.vm.provision :shell, :inline => "sudo ifconfig eth1 <%= server.ip] %> netmask 255.255.255.0 up"
  end
<% end %>
end
    RUBY
    File::open("#{@new_project_folder}/config/templates/Vagrant.erb", "w")do |f|
      f.write(content)
    end
  end

  # Modify the local hosts file taking into account the settings into vagrant hiera file
  def config_local_hosts_file
    template = Tilt::ERBTemplate.new("#{@new_project_folder}/config/templates/local_servers.erb")
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

  def installed_vagrant_box_names
    (`vagrant box list`).split("\n").map{|vagrant_box| vagrant_box.split(' ').first}
  end
end
#Builder.create_local_server_template
#Builder.config_local_hosts_file([server.new(ip: '127.0.0.2', hostname: 'ps' )],'test')
