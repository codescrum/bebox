require 'tilt'
require 'bebox/environment'
require 'bebox/provision'
require 'bebox/logger'

module Bebox
  class Project

    include Bebox::Logger

    attr_accessor :name, :vagrant_box_base, :parent_path, :vagrant_box_provider, :environments, :path, :created_at

    def initialize(name, vagrant_box_base, parent_path, vagrant_box_provider, default_environments = [])
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
      create_puppet_base
      create_project_config
      create_checkpoints
      info "Bundle project ..."
      bundle_project
    end

    # Obtain the project name without 'bebox_' prefix
    def shortname
      self.name.gsub("bebox_", "")
    end

    # Create project directory
    def create_project_directory
      `mkdir -p #{self.parent_path}/#{self.name}`
    end

    # Generate project config files
    def create_project_config
      # Create deploy directories
      create_config_deploy_directories
      # Generate dot files
      generate_dot_bebox_file
      generate_gitignore_file
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

    # Get short project name from the .bebox file
    def self.shortname_from_file(project_root)
      project_name = self.name_from_file(project_root)
      project_name.gsub("bebox_", "")
    end

    # Get Project name from the .bebox file
    def self.name_from_file(project_root)
      project_config = YAML.load_file("#{project_root}/.bebox")
      project_config['project']
    end

    # Create rbenv local
    def generate_ruby_version
      File.open("#{self.path}/.ruby-version", 'w') do |f|
        f.write RUBY_VERSION
      end
    end

    # Generate .bebox file
    def generate_dot_bebox_file
      # Set the creation time for the project
      self.created_at = DateTime.now.to_s
      # Create the .bebox file from template
      dotbebox_template = Tilt::ERBTemplate.new("#{Bebox::Project.templates_path}/project/dot_bebox.erb")
      File.open("#{self.path}/.bebox", 'w') do |f|
        f.write dotbebox_template.render(nil, project: self)
      end
    end

    # Generate .gitignore file
    def generate_gitignore_file
      gitignore_template = Tilt::ERBTemplate.new("#{Bebox::Project.templates_path}/project/gitignore.erb")
      File.open("#{self.path}/.gitignore", 'w') do |f|
        f.write gitignore_template.render(nil, steps: Bebox::PROVISION_STEP_NAMES)
      end
    end

    # Create templates directories
    def create_templates_directories
      `cd #{self.path} && mkdir -p templates/{roles,profiles}`
    end

    # Create the default base roles and profiles in the project
    def copy_default_roles_profiles
      # Copy default roles and profiles to project templates directory
      `cp -R #{Bebox::Project.templates_path}/puppet/default_roles/* #{self.path}/templates/roles/`
      `cp -R #{Bebox::Project.templates_path}/puppet/default_profiles/* #{self.path}/templates/profiles/`
      # Copy default roles and profiles to project roles and profiles available
      `cp -R #{Bebox::Project.templates_path}/puppet/default_roles/* #{self.path}/puppet/roles/`
      `cp -R #{Bebox::Project.templates_path}/puppet/default_profiles/* #{self.path}/puppet/profiles/`
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
      # Create templates directories
      create_templates_directories
      # Generate SO dependencies files
      generate_so_dependencies_files
      # Copy puppet install files
      copy_puppet_install_files
      # Generate steps directories
      generate_steps_directories
      # Generate steps templates
      generate_steps_templates
      # Copy the default_roles and default_profiles to project
      copy_default_roles_profiles
    end

    # Generate steps directories
    def generate_steps_directories
      Bebox::PROVISION_STEP_NAMES.each{|step| `cd #{self.path} && mkdir -p puppet/steps/#{step}/{hiera/data,manifests,modules}`}
      `cd #{self.path} && mkdir -p puppet/{roles,profiles}`
    end

    # Generate steps templates for hiera and manifests files
    def generate_steps_templates
      Bebox::PROVISION_STEPS.each do |step|
        ssh_key = ''
        step_dir = Bebox::Provision.step_name(step)
        templates_path = Bebox::Project::templates_path
        # Generate site.pp template
        manifest_template = Tilt::ERBTemplate.new("#{templates_path}/puppet/#{step}/manifests/site.pp.erb")
        File.open("#{self.path}/puppet/steps/#{step_dir}/manifests/site.pp", 'w') do |f|
          f.write manifest_template.render(nil, :nodes => [])
        end
        # Generate hiera.yaml template
        hiera_template = Tilt::ERBTemplate.new("#{templates_path}/puppet/#{step}/hiera/hiera.yaml.erb")
        File.open("#{self.path}/puppet/steps/#{step_dir}/hiera/hiera.yaml", 'w') do |f|
          f.write hiera_template.render(nil, :step_dir => step_dir)
        end
        # Generate common.yaml template
        hiera_template = Tilt::ERBTemplate.new("#{templates_path}/puppet/#{step}/hiera/data/common.yaml.erb")
        File.open("#{self.path}/puppet/steps/#{step_dir}/hiera/data/common.yaml", 'w') do |f|
          f.write hiera_template.render(nil, :step_dir => step_dir, :ssh_key => ssh_key, :project_name => self.shortname)
        end
      end
    end

    # Copy puppet install files
    def copy_puppet_install_files
      `cd #{self.path} && mkdir -p puppet/lib/deb`
      `cp -R #{lib_path}/deb/* #{self.path}/puppet/lib/deb/`
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
      system("cd #{self.path} && BUNDLE_GEMFILE=Gemfile bundle install")
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

    # Obtain the ssh public key from file in environment
    def self.public_ssh_key_from_file(project_root, environment)
      ssh_key_path = "#{project_root}/config/keys/environments/#{environment}/id_rsa.pub"
      return (File.exist?(ssh_key_path)) ? File.read(ssh_key_path).strip : ''
    end

    # Delete all files referent to a project
    def destroy
      `cd #{self.parent_path} && rm -rf #{self.name}`
    end
  end
end