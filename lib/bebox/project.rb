require 'tilt'
require "bebox/server"
module Bebox
  class Project

		attr_accessor :name, :servers, :vbox_path, :vagrant_box_base_name, :vagrant_box_provider, :parent_path, :path, :local_hosts_file_location, :environments

    def initialize(name, servers, vbox_path, vagrant_box_base_name, parent_path = Dir.pwd, vagrant_box_provider = 'virtualbox')
      self.name = name
      self.servers = servers
      self.vbox_path= vbox_path
      self.vagrant_box_base_name = vagrant_box_base_name
      self.vagrant_box_provider = vagrant_box_provider
      self.parent_path = parent_path
      self.path = "#{self.parent_path}/#{self.name}"
      self.local_hosts_file_location = RUBY_PLATFORM =~ /darwin/ ? '/private/etc' : '/etc'
    end

		# Project creation (phase 1)
    def create
    	create_project_directory
    	create_subdirectories
    end

		# Project dependency installation (phase 2)
    def install_dependencies
    	create_gemfile
    	setup_bundle
    end

		# Run vagrant boxes for configure nodes in project (phase 3)
    def run_vagrant_environment
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

    # Create Gemfile for the project
    def create_gemfile
      gemfile_content = File.read('templates/Gemfile')
      File::open("#{self.path}/Gemfile", "w")do |f|
        f.write(gemfile_content)
      end
    end

    # Generate the vagrantfile
    def generate_vagrantfile
      template = Tilt::ERBTemplate.new("templates/Vagrantfile.erb")
      File.open("#{self.path}/Vagrantfile", 'w') do |f|
        f.write template.render(@servers, :vagrant_box_base_name => @vagrant_box_base_name)
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
      @servers.size.times do |i|
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

  end
end