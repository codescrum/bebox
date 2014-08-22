require 'bebox/files_helper'
require 'bebox/logger'

module Bebox
  module VagrantHelper

    include Bebox::Logger
    include Bebox::FilesHelper

    # Return the existence status of vagrant node
    def vagrant_box_exist?(node)
      vagrant_boxes = `cd #{node.project_root} && vagrant box list`
      project_name = Bebox::Project.name_from_file(node.project_root)
      vagrant_box_provider = Bebox::Project.vagrant_box_provider_from_file(node.project_root)
      (vagrant_boxes =~ /#{project_name}-#{node.hostname}\s+\(#{vagrant_box_provider}/) ? true : false
    end

    # Return the running status of vagrant node
    def vagrant_box_running?(node)
      status = `cd #{node.project_root} && vagrant status`
      (status =~ /#{node.hostname}\s+running/) ? true : false
    end

    # Remove the specified boxes from vagrant
    def remove_vagrant_box(node)
      return unless (node.environment == 'vagrant' && node.prepared_nodes_count > 0)
      project_name = Bebox::Project.name_from_file(node.project_root)
      vagrant_box_provider = Bebox::Project.vagrant_box_provider_from_file(node.project_root)
      `cd #{node.project_root} && vagrant destroy -f #{node.hostname}`
      `cd #{node.project_root} && vagrant box remove #{project_name}-#{node.hostname} --provider #{vagrant_box_provider}`
    end

    # Backup and add the vagrant hosts to local hosts file
    def configure_local_hosts(project_name, node)
      info "\nPlease provide your local password, if ask you, to configure the local hosts file."
      backup_local_hosts(project_name)
      add_to_local_hosts(node)
    end

    # Backup the local hosts file
    def backup_local_hosts(project_name)
      hosts_backup_file = "#{local_hosts_path}/hosts_before_#{project_name}"
      `sudo cp #{local_hosts_path}/hosts #{hosts_backup_file}` unless File.exist?(hosts_backup_file)
    end

    # Add the vagrant hosts to the local hosts file
    def add_to_local_hosts(node)
      host_command = `echo '#{node.ip} #{node.hostname}     # Added by bebox' >> #{local_hosts_path}/hosts`
      host_command if (file_content_trimmed("#{local_hosts_path}/hosts") =~ /#{node.ip}\s+#{node.hostname}/)
    end

    # Obtain the local hosts file for the OS
    def local_hosts_path
      RUBY_PLATFORM =~ /darwin/ ? '/private/etc' : '/etc'
    end

    # Prepare the vagrant nodes
    def prepare_vagrant(node)
      project_name = Bebox::Project.name_from_file(node.project_root)
      vagrant_box_base = Bebox::Project.vagrant_box_base_from_file(node.project_root)
      configure_local_hosts(project_name, node)
      add_vagrant_node(project_name, vagrant_box_base, node)
    end

    # Add the boxes to vagrant for each node
    def add_vagrant_node(project_name, vagrant_box_base, node)
      already_installed_boxes = installed_vagrant_box_names(node)
      box_name = "#{project_name}-#{node.hostname}"
      info "Adding server to vagrant: #{node.hostname}..."
      `cd #{node.project_root} && vagrant box add #{box_name} #{vagrant_box_base}` unless already_installed_boxes.include? box_name
    end

    # Up the vagrant boxes in Vagrantfile
    def self.up_vagrant_nodes(project_root)
      `cd #{project_root} && vagrant up --provision`
    end

    # Halt the vagrant boxes running
    def self.halt_vagrant_nodes(project_root)
      `cd #{project_root} && vagrant halt`
    end

    # Generate the Vagrantfile
    def self.generate_vagrantfile(nodes)
      project_root = nodes.first.project_root
      network_interface = RUBY_PLATFORM =~ /darwin/ ? 'en0' : 'eth0'
      project_name = Bebox::Project.name_from_file(project_root)
      vagrant_box_provider = Bebox::Project.vagrant_box_provider_from_file(project_root)
      generate_file_from_template("#{Bebox::FilesHelper::templates_path}/node/Vagrantfile.erb", "#{project_root}/Vagrantfile", {nodes: nodes, project_name: project_name, vagrant_box_provider: vagrant_box_provider, network_interface: network_interface})
    end

    # return an Array with the names of the currently installed vagrant boxes
    # @returns Array
    def installed_vagrant_box_names(node)
      (`cd #{node.project_root} && vagrant box list`).split("\n").map{|vagrant_box| vagrant_box.split(' ').first}
    end
  end
end