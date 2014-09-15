
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
      create_config_base
      generate_deploy_files
      generate_hiera_template
    end

    # Delete all files and directories related to an environment
    def remove
      remove_checkpoints
      remove_config
      remove_hiera_template
    end

    # Lists existing environments
    def self.list(project_root)
      Dir["#{project_root}/.checkpoints/*/*"].map { |f| File.basename(f) }
    end

    # Create checkpoints base directories
    def create_checkpoints
      FileUtils.cd(self.project_root) { FileUtils.mkdir_p ".checkpoints/environments/#{self.name}/phases" }
      FileUtils.cd("#{project_root}/.checkpoints/environments/#{self.name}/phases") { FileUtils.mkdir_p %w{phase-0 phase-1 phase-2} }
      (0..3).each{ |i| FileUtils.cd(self.project_root) { FileUtils.mkdir_p ".checkpoints/environments/#{self.name}/phases/phase-2/steps/step-#{i}" } }
    end

    # Remove checkpoints base directories
    def remove_checkpoints
      FileUtils.cd(self.project_root) { FileUtils.rm_rf ".checkpoints/environments/#{self.name}" }
    end

    # Create config base for environment
    def create_config_base
      # Create keys directory for environment
      FileUtils.cd(self.project_root) { FileUtils.mkdir_p "config/environments/#{self.name}" }
      FileUtils.cd("#{project_root}/config/environments/#{self.name}") { FileUtils.mkdir_p %w{steps keys} }
      # Create ssh key for puppet user if environment is vagrant
      generate_puppet_user_keys('vagrant') if self.name == 'vagrant'
    end

    # Remove config for environment
    def remove_config
      FileUtils.cd(self.project_root) { FileUtils.rm_rf "config/environments/#{self.name}" }
    end

    # Generate the deploy files for the environment
    def generate_deploy_files
      template_name = (self.name == 'vagrant') ? 'vagrant' : "environment"
      # Generate capistrano specific steps recipes
      Bebox::PROVISION_STEPS.each do |step|
        generate_file_from_template("#{templates_path}/project/config/deploy/steps/#{step}.erb", "#{self.project_root}/config/environments/#{name}/steps/#{step}.rb", {})
      end
      # Generate capistrano recipe for environment
      generate_file_from_template("#{templates_path}/project/config/deploy/#{template_name}.erb", "#{self.project_root}/config/environments/#{name}/deploy.rb", {nodes: nil, environment: self.name})
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

    # Remove the hiera data template file for the environment
    def remove_hiera_template
      Bebox::PROVISION_STEP_NAMES.each {|step| FileUtils.cd(self.project_root) { FileUtils.rm_rf "puppet/steps/#{step}/hiera/data/#{self.name}.yaml" } }
    end

    # Path to the templates directory in the gem
    def templates_path
      Pathname(__FILE__).dirname.parent + 'templates'
      # File.join((File.expand_path '..', File.dirname(__FILE__)), 'templates')
    end

    # Generate ssh keys for connection with puppet user in environment
    def generate_puppet_user_keys(environment)
      require 'sshkey'
      FileUtils.cd("#{self.project_root}/config/environments/#{environment}/keys") { FileUtils.rm Dir.glob('*') }
      sshkey = SSHKey.generate(:type => "RSA", :bits => 1024)
      FileUtils.cd("#{self.project_root}/config/environments/#{environment}/keys") do
        write_content_to_file("#{self.project_root}/config/environments/#{environment}/keys/id_rsa", sshkey.private_key)
        write_content_to_file("#{self.project_root}/config/environments/#{environment}/keys/id_rsa.pub", sshkey.ssh_public_key)
      end
    end

    # Check if the environment has ssh keys configured
    def self.check_environment_access(project_root, environment)
      key_exist = File.exist?("#{project_root}/config/environments/#{environment}/keys/id_rsa")
      key_exist &&= File.exist?("#{project_root}/config/environments/#{environment}/keys/id_rsa.pub")
    end

    # Check if there's an existing environment in the project
    def self.environment_exists?(project_root, environment_name)
      Dir.exists?("#{project_root}/.checkpoints/environments/#{environment_name}")
    end
  end
end