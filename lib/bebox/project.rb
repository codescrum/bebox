require 'tilt'
require 'bebox/server'
require 'bebox/environment'

module Bebox
  class Project

		attr_accessor :name, :vagrant_box_base, :parent_path, :vagrant_box_provider, :environments, :path

    def initialize(name, vagrant_box_base, parent_path, vagrant_box_provider, default_environments)
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

    # Get Project vagrant box provider from the .bebox file
    def self.vagrant_box_provider_from_file(project_root)
      project_config = YAML.load_file("#{project_root}/.bebox")
      project_config['vagrant_box_provider']
    end

    # Get Project vagrant box base from the .bebox file
    def self.vagrant_box_base_from_file(project_root)
      project_config = YAML.load_file("#{project_root}/.bebox")
      project_config['vagrant_box_base']
    end

    # Get Project name from the .bebox file
    def self.name_from_file(project_root)
      project_config = YAML.load_file("#{project_root}/.bebox")
      project_config['project']
    end

    # Create rbenv local
    def generate_ruby_version
      `cd #{self.path} && rbenv local 2.1.0`
    end

    # Generate .bebox file
    def generate_dot_bebox_file
      dotbebox_template = Tilt::ERBTemplate.new("#{Bebox::Project.templates_path}/project/dot_bebox.erb")
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

    # Create Capfile for the project
    def create_capfile
      capfile_content = File.read("#{Bebox::Project.templates_path}/project/Capfile.erb")
      File::open("#{self.path}/Capfile", "w")do |f|
        f.write(capfile_content)
      end
    end

    # Create Gemfile for the project
    def create_gemfile
      gemfile_content = File.read("#{Bebox::Project.templates_path}/project/Gemfile.erb")
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
      ubuntu_dependencies_content = File.read("#{Bebox::Project.templates_path}/project/ubuntu_dependencies")
      File::open("#{self.path}/puppet/prepare/dependencies/ubuntu/packages", "w")do |f|
        f.write(ubuntu_dependencies_content)
      end
    end

    def self.so_dependencies
      File.read("#{Bebox::Project.templates_path}/project/ubuntu_dependencies").gsub(/\s+/, ' ')
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
      config_deploy_template = Tilt::ERBTemplate.new("#{Bebox::Project.templates_path}/project/config/deploy.erb")
      File.open("#{self.path}/config/deploy.rb", 'w') do |f|
        f.write config_deploy_template.render(nil, project: self)
      end
    end

    # Path to the lib directory in the gem
    def lib_path
      File.expand_path '..', File.dirname(__FILE__)
    end

    # Path to the templates directory in the gem
    def self.templates_path
      # File.expand_path(File.join(File.dirname(__FILE__), "..", "gems/bundler/lib/templates"))
      File.join((File.expand_path '..', File.dirname(__FILE__)), 'templates')
    end

  end
end