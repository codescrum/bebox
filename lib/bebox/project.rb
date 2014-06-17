require 'tilt'
require 'bebox/server'
require 'bebox/environment'

module Bebox
  class Project

		attr_accessor :name, :vagrant_box_base, :parent_path, :vagrant_box_provider, :environments, :path
    #:servers,
    def initialize(name, vagrant_box_base, parent_path, vagrant_box_provider, default_environments)
      # self.servers = servers
      self.name = name
      self.vagrant_box_base = vagrant_box_base
      self.parent_path = parent_path
      self.vagrant_box_provider = vagrant_box_provider
      self.environments = []
      self.path = "#{self.parent_path}/#{self.name}"
      default_environments.each do |env|
        self.environments << Bebox::Environment.new(env, self.path)
      end
    end

		# Project creation phase
    def create
    	create_project_directory
      create_project_config
      create_puppet_base
      create_checkpoints
      bundle_project
    end

    # Create project directory
    def create_project_directory
      `mkdir -p #{self.parent_path}/#{self.name}`
    end

    # Generate project config files
    def create_project_config
      # Create deploy directories
      create_config_deploy_directories
      # Generate .bebox file
      generate_dot_bebox_file
      # Generate ruby version file
      generate_ruby_version
      # Generate Capfile and deploy files
      create_capfile
      generate_deploy_file
      # Generate Gemfile
      create_gemfile
      # Create the default environments
      create_default_environments
    end

    # Create rbenv local
    def generate_ruby_version
      `cd #{self.path} && rbenv local 2.1.0`
    end

    # Generate .bebox file
    def generate_dot_bebox_file
      dotbebox_template = Tilt::ERBTemplate.new("#{templates_path}/project/dot_bebox.erb")
      File.open("#{self.path}/.bebox", 'w') do |f|
        f.write dotbebox_template.render(nil, project: self)
      end
    end

    # Create config deploy and keys directories
    def create_config_deploy_directories
      `cd #{self.path} && mkdir -p config/{deploy,keys/environments}`
    end

    # Create the default environments
    def create_default_environments
      self.environments.map{|environment| environment.create}
    end

    # # Create capistrano base
    # def create_capistrano_base
    #   # Create keys directories for each default environment
    #   self.environments.each do |environment|
    #     `cd #{self.path} && mkdir -p config/keys/environments/#{environment.name}`
    #   end
    #   # Create vagrant environment ssh key for puppet user
    #   generate_puppet_user_keys('vagrant')
    # end

    # Create Capfile for the project
    def create_capfile
      capfile_content = File.read("#{templates_path}/project/Capfile.erb")
      File::open("#{self.path}/Capfile", "w")do |f|
        f.write(capfile_content)
      end
    end

    # Create Gemfile for the project
    def create_gemfile
      gemfile_content = File.read("#{templates_path}/project/Gemfile.erb")
      File::open("#{self.path}/Gemfile", "w")do |f|
        f.write(gemfile_content)
      end
    end

    # Create puppet base directories and files
    def create_puppet_base
      # Generate SO dependencies files
      generate_so_dependencies_files
      # Copy puppet install files
      copy_puppet_install_files
      # Generate steps directories
      generate_steps_directories
    end

    # Generate steps directories
    def generate_steps_directories
      puppet_steps = %w{0-fundamental 1-users 2-services 3-security}
      puppet_steps.each{|step| `cd #{self.path} && mkdir -p puppet/steps/#{step}/{hiera/data,manifests,modules}`}
      `cd #{self.path} && mkdir -p puppet/{roles,profiles}`
    end

    # Copy puppet install files
    def copy_puppet_install_files
      `cd #{self.path} && mkdir -p puppet/lib/deb`
      `cp -r #{lib_path}/deb/* #{self.path}/puppet/lib/deb/`
    end

    # Generate SO dependencies files
    def generate_so_dependencies_files
      `cd #{self.path} && mkdir -p puppet/prepare/dependencies/ubuntu`
      ubuntu_dependencies_content = File.read("#{templates_path}/project/ubuntu_dependencies")
      File::open("#{self.path}/puppet/prepare/dependencies/ubuntu/packages", "w")do |f|
        f.write(ubuntu_dependencies_content)
      end
    end


    # Create checkpoints base directories
    def create_checkpoints
      `cd #{self.path} && mkdir -p .checkpoints/environments`
    end

    # Bundle install packages for project
    def bundle_project
      `cd #{self.path} && BUNDLE_GEMFILE=Gemfile bundle install 1>/dev/null`
    end

    # Generate the deploy file for the project
    def generate_deploy_file
      config_deploy_template = Tilt::ERBTemplate.new("#{templates_path}/project/config/deploy.erb")
      File.open("#{self.path}/config/deploy.rb", 'w') do |f|
        f.write config_deploy_template.render(nil, project: self)
      end
    end

    def lib_path
      File.expand_path '..', File.dirname(__FILE__)
    end

    def templates_path
      # File.expand_path(File.join(File.dirname(__FILE__), "..", "gems/bundler/lib/templates"))
      File.join((File.expand_path '..', File.dirname(__FILE__)), 'templates')
    end

		# # Project dependency installation (phase 2)
  #   def install_dependencies
  #   	setup_bundle
  #     setup_capistrano
  #   end

		# # Create project subdirectories
  #   def create_subdirectories
  #     `cd #{self.path} && mkdir -p config/deploy && mkdir -p keys`
  #     `cd #{self.path} && mkdir -p initial_puppet/hiera/data && mkdir -p initial_puppet/manifests && mkdir -p initial_puppet/modules && mkdir -p initial_puppet/lib/deb/puppet_3.6.0`
  #     `cd #{self.path} && mkdir -p puppet/hiera/data && mkdir -p puppet/manifests && mkdir -p puppet/modules`
  #   end


    # # Copy puppet lib files to project initial_puppet
    # def copy_puppet_libs
    #   `cp lib/deb/puppet_3.6.0/*.deb #{self.path}/initial_puppet/lib/deb/puppet_3.6.0`
    # end

    # # Retrieve a environment from the environments array by name
    # def environment_by_name(name)
    #   self.environments.each do |environment|
    #     return environment if environment.name == name
    #   end
    # end
  end
end