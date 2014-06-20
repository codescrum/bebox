require 'tilt'

module Bebox
  class Environment

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
    end

    # Delete all files and directories related to an environment
    def remove
      remove_checkpoints
      remove_capistrano_base
      remove_deploy_file
    end

    # Lists existing environments
    def self.list(project_root)
      Dir["#{project_root}/.checkpoints/*/*"].map { |f| File.basename(f) }
    end

    # Create checkpoints base directories
    def create_checkpoints
      `cd #{self.project_root} && mkdir -p .checkpoints/environments/#{self.name}/{nodes,prepared_nodes,steps}`
      (0..3).each{|i| `cd #{self.project_root} && mkdir -p .checkpoints/environments/#{self.name}/steps/step-#{i}`}
    end

    # Remove checkpoints base directories
    def remove_checkpoints
      `cd #{self.project_root} && rm -rf .checkpoints/environments/#{self.name}`
    end

    # Create capistrano base
    def create_capistrano_base
      # Create keys directory for environment
      `cd #{self.project_root} && mkdir -p config/keys/environments/#{self.name}`
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
      config_deploy_template = Tilt::ERBTemplate.new("#{templates_path}/project/config/deploy/#{template_name}.erb")
      File.open("#{self.project_root}/config/deploy/#{self.name}.rb", 'w') do |f|
        f.write config_deploy_template.render(nil, :nodes => nil)
      end
    end

    # Remove the deploy file for the environment
    def remove_deploy_file
      `cd #{self.project_root} && rm -rf config/deploy/#{self.name}.rb`
    end

    # Path to the templates directory in the gem
    def templates_path
      # File.expand_path(File.join(File.dirname(__FILE__), "..", "gems/bundler/lib/templates"))
      File.join((File.expand_path '..', File.dirname(__FILE__)), 'templates')
    end

    # Generate ssh keys for connection with puppet user in environment
    def generate_puppet_user_keys(environment)
      `cd #{self.project_root}/config/keys/environments/#{environment} && ssh-keygen -f id_rsa -t rsa -N ''`
    end
  end
end