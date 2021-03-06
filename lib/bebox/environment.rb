
module Bebox
  class Environment

    include Bebox::FilesHelper

    attr_accessor :name, :project_root

    def initialize(name, project_root)
      self.name = name
      self.project_root = project_root
    end

    # Create all files and directories related to an environment
    def create
      create_checkpoints
      create_capistrano_base
      generate_deploy_file
      generate_hiera_template
    end

    # Delete all files and directories related to an environment
    def remove
      remove_checkpoints
      remove_capistrano_base
      remove_deploy_file
      remove_hiera_template
    end

    # Lists existing environments
    def self.list(project_root)
      Dir["#{project_root}/.checkpoints/*/*"].map { |f| File.basename(f) }
    end

    # Create checkpoints base directories
    def create_checkpoints
      Bebox::Environment.create_checkpoint_directories(project_root, name)
    end

    # Create checkpoints base directories
    def self.create_checkpoint_directories(project_root, environment)
      `cd #{project_root} && mkdir -p .checkpoints/environments/#{environment}/{nodes,prepared_nodes,steps}`
      (0..3).each{|i| `cd #{project_root} && mkdir -p .checkpoints/environments/#{environment}/steps/step-#{i}`}
    end

    # Remove checkpoints base directories
    def remove_checkpoints
      `cd #{self.project_root} && rm -rf .checkpoints/environments/#{self.name}`
    end

    # Create capistrano base
    def create_capistrano_base
      # Create keys directory for environment
      `cd #{self.project_root} && mkdir -p config/keys/environments/#{self.name}`
      `cd #{self.project_root}/config/keys/environments/#{self.name} && touch .keep`
      # Create ssh key for puppet user if environment is vagrant
      generate_puppet_user_keys('vagrant') if self.name == 'vagrant'
    end

    # Remove capistrano base
    def remove_capistrano_base
      `cd #{self.project_root} && rm -rf config/keys/environments/#{self.name}`
    end

    # Generate the deploy file for the environment
    def generate_deploy_file
      template_name = (self.name == 'vagrant') ? 'vagrant' : "environment"
      generate_file_from_template("#{templates_path}/project/config/deploy/#{template_name}.erb", "#{self.project_root}/config/deploy/#{self.name}.rb", {nodes: nil, environment: self.name})
    end

    # Generate the hiera data template for the environment
    def generate_hiera_template
      ssh_key = Bebox::Project.public_ssh_key_from_file(self.project_root, self.name)
      project_name = Bebox::Project.shortname_from_file(self.project_root)
      Bebox::PROVISION_STEPS.each do |step|
        step_dir = Bebox::Provision.step_name(step)
        generate_file_from_template("#{templates_path}/puppet/#{step}/hiera/data/environment.yaml.erb", "#{self.project_root}/puppet/steps/#{step_dir}/hiera/data/#{self.name}.yaml", {step_dir: step_dir, ssh_key: ssh_key, project_name: project_name})
      end
    end

    # Remove the deploy file for the environment
    def remove_deploy_file
      `cd #{self.project_root} && rm -rf config/deploy/#{self.name}.rb`
    end

    # Remove the hiera data template file for the environment
    def remove_hiera_template
      Bebox::PROVISION_STEP_NAMES.each {|step| `cd #{self.project_root} && rm -rf puppet/steps/#{step}/hiera/data/#{self.name}.yaml` }
    end

    # Path to the templates directory in the gem
    def templates_path
      # File.expand_path(File.join(File.dirname(__FILE__), "..", "gems/bundler/lib/templates"))
      File.join((File.expand_path '..', File.dirname(__FILE__)), 'templates')
    end

    # Generate ssh keys for connection with puppet user in environment
    def generate_puppet_user_keys(environment)
      `rm -f #{self.project_root}/config/keys/environments/#{environment}/{id_rsa,id_rsa.pub}`
      `cd #{self.project_root}/config/keys/environments/#{environment} && ssh-keygen -q -f id_rsa -t rsa -N ''`
    end

    # Check if the environment has ssh keys configured
    def self.check_environment_access(project_root, environment)
      key_exist = File.exist?("#{project_root}/config/keys/environments/#{environment}/id_rsa")
      key_exist &&= File.exist?("#{project_root}/config/keys/environments/#{environment}/id_rsa.pub")
    end

    # Check if there's an existing environment in the project
    def self.environment_exists?(project_root, environment_name)
      Dir.exists?("#{project_root}/.checkpoints/environments/#{environment_name}")
    end
  end
end