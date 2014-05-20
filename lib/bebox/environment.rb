require 'tilt'

module Bebox
  class Environment

    UBUNTU_DEPENDENCIES = %w(git-core build-essential curl)

    attr_accessor :name, :project_path, :servers, :vbox_path, :vagrant_box_base_name, :vagrant_box_provider, :hosts_backup_file, :local_hosts_path

    def initialize(name, project_path, servers, vbox_path, vagrant_box_base_name, vagrant_box_provider)
      self.name = name
      self.project_path = project_path
      self.servers = servers
      self.vbox_path = vbox_path
      self.vagrant_box_base_name = vagrant_box_base_name
      self.vagrant_box_provider = vagrant_box_provider
      self.local_hosts_path = RUBY_PLATFORM =~ /darwin/ ? '/private/etc' : '/etc'
    end

    # Run vagrant boxes for configure nodes in project (phase 3)
    def up
      configure_local_hosts
      generate_vagrantfile
      add_vagrant_boxes
      up_vagrant_nodes
    end

    # Install the common development dependecies with capistrano prepare (phase 4)
    def install_common_dev
      `cd #{self.project_path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{name} deploy:prepare`
    end

    # Generate the Vagrantfile
    def generate_vagrantfile
      template = Tilt::ERBTemplate.new("templates/Vagrantfile.erb")
      File.open("#{self.project_path}/Vagrantfile", 'w') do |f|
        f.write template.render(self.servers, :vagrant_box_base_name => self.vagrant_box_base_name)
      end
    end

    # Add the configured boxes to vagrant
    def add_vagrant_boxes
      already_installed_boxes = installed_vagrant_box_names
      self.servers.each_with_index do |server, index|
        box_name = "#{self.vagrant_box_base_name}_#{index}"
        puts "  Adding server: #{server.hostname}..."
        `cd #{self.project_path} && vagrant box add #{box_name} #{vbox_path}` unless already_installed_boxes.include? box_name
      end
    end

    # Remove the specified boxes from vagrant
    def remove_vagrant_boxes
      self.servers.size.times do |i|
        `cd #{self.project_path} && vagrant destroy -f node_#{i}`
        `cd #{self.project_path} && vagrant box remove #{self.vagrant_box_base_name}_#{i} #{self.vagrant_box_provider}`
      end
    end

    # Up the vagrant boxes in Vagrantfile
    def up_vagrant_nodes
      `cd #{self.project_path} && vagrant up --provision`
    end

    # Halt the vagrant boxes running
    def halt_vagrant_nodes
      `cd #{self.project_path} && vagrant halt`
    end

    # return an Array with the names of the currently installed vagrant boxes
    # @returns Array
    def installed_vagrant_box_names
      (`cd #{self.project_path} && vagrant box list`).split("\n").map{|vagrant_box| vagrant_box.split(' ').first}
    end

    # return an String with the status of vagrant boxes
    # @returns String
    def vagrant_nodes_status
      `cd #{self.project_path} && vagrant status`
    end

    # Backup and add the vagrant hosts to local hosts file
    def configure_local_hosts
      backup_local_hosts
      add_to_local_hosts
    end

    # Add the vagrant hosts to the local hosts file
    def add_to_local_hosts
      # Get the content of the hosts file
      hosts_content = File.read("#{self.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
      # For each server it adds a line to the hosts file if this not exist
      self.servers.each do |server|
        line = "#{server.ip} #{server.hostname}"
        server_present = (hosts_content =~ /#{server.ip}\s+#{server.hostname}/) ? true : false
        `sudo echo '#{line}     # Added by bebox' | sudo tee -a #{self.local_hosts_path}/hosts` unless server_present
      end
    end

    # Backup the local hosts file
    def backup_local_hosts
      # Make a backup of hosts file with the actual datetime
      self.hosts_backup_file = "#{self.local_hosts_path}/hosts_#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}"
      `sudo cp #{self.local_hosts_path}/hosts #{self.hosts_backup_file}`
    end

    # Restore the previous local hosts file
    def restore_local_hosts
      `sudo cp #{self.hosts_backup_file} #{self.local_hosts_path}/hosts`
      `sudo rm #{self.hosts_backup_file}`
      self.hosts_backup_file = ''
    end
  end
end