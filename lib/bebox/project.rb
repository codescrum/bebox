require 'tilt'
require "bebox/server"
require "bebox/environment"

module Bebox
  class Project

		attr_accessor :name, :servers, :vbox_path, :vagrant_box_base_name, :vagrant_box_provider, :parent_path, :path, :environments

    def initialize(name, servers, vbox_path, vagrant_box_base_name, parent_path = Dir.pwd, vagrant_box_provider = 'virtualbox', environments = [])
      self.name = name
      self.servers = servers
      self.vbox_path= vbox_path
      self.vagrant_box_base_name = vagrant_box_base_name
      self.vagrant_box_provider = vagrant_box_provider
      self.parent_path = parent_path
      self.path = "#{self.parent_path}/#{self.name}"
      self.environments = []
      environments.each do |env|
        self.environments << Bebox::Environment.new(env, self.path, self.servers, self.vbox_path, self.vagrant_box_base_name, self.vagrant_box_provider)
      end
    end

		# Project creation (phase 1)
    def create
    	create_project_directory
    	create_subdirectories
      copy_puppet
    end

		# Project dependency installation (phase 2)
    def install_dependencies
    	setup_bundle
      setup_capistrano
    end

		# Run vagrant boxes for configure nodes in project (phase 3)
    def run_vagrant_environment
      self.environments.each do |environment|
        environment.up if environment.name == 'vagrant'
      end
    end

    # Install common dev packages for the environment (phase 4)
    def install_common_dev_environment
      self.environments.each do |environment|
        environment.install_common_dev if environment.name == 'vagrant'
      end
    end

    # Install puppet for the environment (phase 5)
    def install_puppet
      self.environments.each do |environment|
        Puppet.install if environment.name == 'vagrant'
      end
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
      gemfile_content = File.read('templates/Gemfile.erb')
      File::open("#{self.path}/Gemfile", "w")do |f|
        f.write(gemfile_content)
      end
    end

    # Generate the deploy files for each project environment
    def generate_deploy_files
      config_deploy_template = Tilt::ERBTemplate.new("templates/config/deploy.erb")
      File.open("#{self.path}/config/deploy.rb", 'w') do |f|
        f.write config_deploy_template.render(self)
      end
      self.environments.each do |environment|
        template_name = (environment.name == 'vagrant') ? "vagrant" : "environment"
        config_deploy_template = Tilt::ERBTemplate.new("templates/config/deploy/#{template_name}.erb")
        File.open("#{self.path}/config/deploy/#{environment.name}.rb", 'w') do |f|
          f.write config_deploy_template.render(self)
        end
      end
    end

    # Create Capfile for the project
    def create_capfile
      capfile_content = File.read('templates/Capfile.erb')
      File::open("#{self.path}/Capfile", "w")do |f|
        f.write(capfile_content)
      end
    end

    def copy_puppet
      `cp -r puppet #{self.path}`
    end

    def environment_by_name(name)
      self.environments.each do |environment|
        return environment if environment.name == name
      end
    end
  end
end