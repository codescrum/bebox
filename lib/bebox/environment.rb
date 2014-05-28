require 'tilt'

module Bebox
  class Environment

    UBUNTU_DEPENDENCIES = %w(git-core build-essential curl whois openssl libxslt1-dev autoconf bison libreadline6-dev)

    attr_accessor :name, :project, :local_hosts_path, :hosts_backup_file

    def initialize(name, project)
      self.name = name
      self.project = project
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
      config_initial_puppet
      `cd #{self.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{name} deploy:prepare_common_dev -s phase='common_dev'`
    end

    def config_initial_puppet
      config_initial_hiera
      config_manifests
    end

    def config_initial_hiera
      hiera_template = Tilt::ERBTemplate.new("templates/initial_puppet/hiera/hiera.yaml.erb")
      File.open("#{self.project.path}/initial_puppet/hiera/hiera.yaml", 'w') do |f|
        f.write hiera_template.render(nil)
      end
      common_hiera_template = Tilt::ERBTemplate.new("templates/initial_puppet/hiera/data/common.yaml.erb")
      ssh_puppet_key = File.read("#{self.project.path}/keys/puppet.rsa.pub")
      File.open("#{self.project.path}/initial_puppet/hiera/data/common.yaml", 'w') do |f|
        f.write common_hiera_template.render(self, :puppet_key => ssh_puppet_key)
      end
    end

    def config_manifests
      `cp templates/initial_puppet/manifests/site.pp #{self.project.path}/initial_puppet/manifests`
      `cp -r templates/initial_puppet/modules/* #{self.project.path}/initial_puppet/modules`
    end

    # Generate the Vagrantfile
    def generate_vagrantfile
      template = Tilt::ERBTemplate.new("templates/Vagrantfile.erb")
      File.open("#{self.project.path}/Vagrantfile", 'w') do |f|
        f.write template.render(self.project.servers, :vagrant_box_base_name => self.project.vagrant_box_base_name)
      end
    end

    # Add the configured boxes to vagrant
    def add_vagrant_boxes
      already_installed_boxes = installed_vagrant_box_names
      self.project.servers.each_with_index do |server, index|
        box_name = "#{self.project.vagrant_box_base_name}_#{index}"
        puts "  Adding server: #{server.hostname}..."
        `cd #{self.project.path} && vagrant box add #{box_name} #{self.project.vbox_path}` unless already_installed_boxes.include? box_name
      end
    end

    # Remove the specified boxes from vagrant
    def remove_vagrant_boxes
      self.project.servers.size.times do |i|
        `cd #{self.project.path} && vagrant destroy -f node_#{i}`
        `cd #{self.project.path} && vagrant box remove #{self.project.vagrant_box_base_name}_#{i} #{self.project.vagrant_box_provider}`
      end
    end

    # Up the vagrant boxes in Vagrantfile
    def up_vagrant_nodes
      `cd #{self.project.path} && vagrant up --provision`
    end

    # Halt the vagrant boxes running
    def halt_vagrant_nodes
      `cd #{self.project.path} && vagrant halt`
    end

    # return an Array with the names of the currently installed vagrant boxes
    # @returns Array
    def installed_vagrant_box_names
      (`cd #{self.project.path} && vagrant box list`).split("\n").map{|vagrant_box| vagrant_box.split(' ').first}
    end

    # return an String with the status of vagrant boxes
    # @returns String
    def vagrant_nodes_status
      `cd #{self.project.path} && vagrant status`
    end

    # Backup and add the vagrant hosts to local hosts file
    def configure_local_hosts
      puts 'Please provide your root password, if asked, to configure the local hosts file'
      backup_local_hosts
      add_to_local_hosts
    end

    # Add the vagrant hosts to the local hosts file
    def add_to_local_hosts
      # Get the content of the hosts file
      hosts_content = File.read("#{self.local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
      # For each server it adds a line to the hosts file if this not exist
      self.project.servers.each do |server|
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