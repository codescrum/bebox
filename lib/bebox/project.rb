require 'tilt'
require "bebox/server"
module Bebox
  class Project

		attr_accessor :name, :servers, :vbox_uri, :vagrant_box_base_name, :vagrant_box_provider, :parent_path, :path, :local_hosts_file_location

    def initialize(name, servers, vbox_uri, vagrant_box_base_name, parent_path = Dir.pwd, vagrant_box_provider = 'virtualbox')
      self.name = name
      self.servers = servers
      self.vbox_uri= vbox_uri
      self.vagrant_box_base_name = vagrant_box_base_name
      self.vagrant_box_provider = vagrant_box_provider
      self.parent_path = parent_path
      self.path = "#{self.parent_path}/#{self.name}"
      self.local_hosts_file_location = RUBY_PLATFORM =~ /darwin/ ? '/private/etc' : '/etc'
    end

		# Project creation phase
    def create
    	create_project_directory
    	create_subdirectories
    end

    # Create project directory
    def create_project_directory
      `cd #{self.parent_path} && mkdir -p #{self.name}`
    end

		# Create project subdirectories
    def create_subdirectories
      `cd #{self.path} && mkdir -p config && mkdir -p config/deploy`
    end

		# Project dependency installation
    def install_dependencies
    	create_gemfile
    	setup_bundle
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
  end
end