require 'tilt'
require "bebox/server"
require "bebox/environment"

module Bebox
  class Project

		attr_accessor :name, :servers, :vbox_path, :vagrant_box_base_name, :vagrant_box_provider, :parent_path, :path, :hosts_path, :hosts_backup_file, :environments

    def initialize(name, servers, vbox_path, vagrant_box_base_name, parent_path = Dir.pwd, vagrant_box_provider = 'virtualbox', environments = [])
      self.name = name
      self.servers = servers
      self.vbox_path= vbox_path
      self.vagrant_box_base_name = vagrant_box_base_name
      self.vagrant_box_provider = vagrant_box_provider
      self.parent_path = parent_path
      self.path = "#{self.parent_path}/#{self.name}"
      self.hosts_path = RUBY_PLATFORM =~ /darwin/ ? '/private/etc' : '/etc'
      self.environments = []
      environments.each do |env|
        self.environments << Bebox::Environment.new(env, self)
      end
    end

		# Project creation (phase 1)
    def create
    	create_project_directory
    	create_subdirectories
    end

		# Project dependency installation (phase 2)
    def install_dependencies
    	setup_bundle
      setup_capistrano
    end

		# Run vagrant boxes for configure nodes in project (phase 3)
    def run_vagrant_environment
      configure_local_hosts
    	generate_vagrantfile
    	add_vagrant_boxes
    	up_vagrant_nodes
    end

    # Create project directory
    def create_project_directory
      `cd #{self.parent_path} && mkdir -p #{self.name}`
    end

		# Create project subdirectories
    def create_subdirectories
      `cd #{self.path} && mkdir -p config && mkdir -p config/deploy`
    end

    # Create Gemfile for the project and run bundle_install
    def setup_bundle
      create_gemfile
      `cd #{self.path} && BUNDLE_GEMFILE=Gemfile bundle install`
    end

    # Create Capfile and deploy files
    def setup_capistrano
      create_capfile
      generate_deploy_files
    end

    # Create Gemfile for the project
    def create_gemfile
      gemfile_content = File.read('templates/Gemfile')
      File::open("#{self.path}/Gemfile", "w")do |f|
        f.write(gemfile_content)
      end
    end

    # Generate the Vagrantfile
    def generate_vagrantfile
      template = Tilt::ERBTemplate.new("templates/Vagrantfile.erb")
      File.open("#{self.path}/Vagrantfile", 'w') do |f|
        f.write template.render(self.servers, :vagrant_box_base_name => self.vagrant_box_base_name)
      end
    end

    # Generate the deploy files for each project environment
    def generate_deploy_files
      config_deploy_template = Tilt::ERBTemplate.new("templates/config_deploy.erb")
      File.open("#{self.path}/config/deploy.rb", 'w') do |f|
        f.write config_deploy_template.render(self)
      end
      self.environments.each do |environment|
        template_name = (environment.name == 'vagrant') ? "vagrant" : "environment"
        config_deploy_template = Tilt::ERBTemplate.new("templates/config_deploy_#{template_name}.erb")
        File.open("#{self.path}/config/deploy/#{environment.name}.rb", 'w') do |f|
          f.write config_deploy_template.render(self)
        end
      end
    end

    # Create Capfile for the project
    def create_capfile
      capfile_content = File.read('templates/Capfile')
      File::open("#{self.path}/Capfile", "w")do |f|
        f.write(capfile_content)
      end
    end

    # Add the specified boxes and init vagrant to create Vagrantfile
    def add_vagrant_boxes
      already_installed_boxes = installed_vagrant_box_names
      self.servers.each_with_index do |server, index|
        box_name = "#{self.vagrant_box_base_name}_#{index}"
        puts "  Adding server: #{server.hostname}..."
        `cd #{self.path} && vagrant box add #{box_name} #{vbox_path}` unless already_installed_boxes.include? box_name
      end
    end

    # Remove the specified boxes from vagrant
    def remove_vagrant_boxes
      self.servers.size.times do |i|
        `cd #{self.path} && vagrant destroy -f node_#{i}`
        `cd #{self.path} && vagrant box remove #{self.vagrant_box_base_name}_#{i} #{self.vagrant_box_provider}`
      end
    end

    # Up the vagrant boxes in Vagrantfile
    def up_vagrant_nodes
      `cd #{self.path} && vagrant up --provision`
    end

    # Halt the vagrant boxes running
    def halt_vagrant_nodes
      `cd #{self.path} && vagrant halt`
    end

    # return an Array with the names of the currently installed vagrant boxes
    # @returns Array
    def installed_vagrant_box_names
      (`cd #{self.path} && vagrant box list`).split("\n").map{|vagrant_box| vagrant_box.split(' ').first}
    end

    # return an String with the status of vagrant boxes
    # @returns String
    def vagrant_nodes_status
      `cd #{self.path} && vagrant status`
    end

    # Backup and add the vagrant hosts to local hosts file
    def configure_local_hosts
      backup_local_hosts
      add_to_local_hosts
    end

    # Add the vagrant hosts to the local hosts file
    def add_to_local_hosts
      # Get the content of the hosts file
      hosts_content = File.read("#{self.hosts_path}/hosts").gsub(/\s+/, ' ').strip
      # For each server it adds a line to the hosts file if this not exist
      self.servers.each do |server|
        line = "#{server.ip} #{server.hostname}"
        server_present = (hosts_content =~ /#{server.ip}\s+#{server.hostname}/) ? true : false
        `sudo echo '#{line}     # Added by bebox' | sudo tee -a #{self.hosts_path}/hosts` unless server_present
      end
    end

    # Backup the local hosts file
    def backup_local_hosts
      # Make a backup of hosts file with the actual datetime
      self.hosts_backup_file = "#{self.hosts_path}/hosts_#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}"
      `sudo cp #{self.hosts_path}/hosts #{self.hosts_backup_file}`
    end

    # Restore the previous local hosts file
    def restore_local_hosts
      `sudo cp #{self.hosts_backup_file} #{self.hosts_path}/hosts`
      `sudo rm #{self.hosts_backup_file}`
      self.hosts_backup_file = ''
    end

  end
end