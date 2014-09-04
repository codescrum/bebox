
module Bebox
  class Node

    include Bebox::Logger
    include Bebox::FilesHelper
    include Bebox::VagrantHelper

    attr_accessor :environment, :project_root, :hostname, :ip, :created_at, :started_at, :finished_at

    def initialize(environment, project_root, hostname, ip)
      self.environment = environment
      self.project_root = project_root
      self.hostname = hostname
      self.ip = ip
    end

    # Create all files and directories related to an node
    def create
      create_hiera_template
      create_manifests_node
      create_node_checkpoint
    end

    # Delete all files and directories related to an node
    def remove
      remove_vagrant_box(self)
      remove_checkpoints
      remove_hiera_template
      remove_manifests_node
    end

    # List existing nodes for environment and type (nodes, prepared_nodes)
    def self.list(project_root, environment, node_type)
      Dir["#{environments_path(project_root)}/#{environment}/#{node_type}/*"].map { |f| File.basename(f, ".*") }
    end

    # Get node checkpoint parameter from the yml file
    def checkpoint_parameter_from_file(node_type, parameter)
      Bebox::Node.checkpoint_parameter_from_file(self.project_root, self.environment, self.hostname, node_type, parameter)
    end

    # Get node checkpoint parameter from the yml file
    def self.checkpoint_parameter_from_file(project_root, environment, hostname, node_type, parameter)
      node_config = YAML.load_file("#{environments_path(project_root)}/#{environment}/#{node_type}/#{hostname}.yml")
      node_config[parameter]
    end

    # Prepare the configured nodes
    def prepare
      started_at = DateTime.now.to_s
      prepare_deploy
      prepare_common_installation
      puppet_installation
      create_prepare_checkpoint(started_at)
    end

    # Deploy the puppet prepare directory
    def prepare_deploy
      `cd #{self.project_root} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment} deploy:setup -S phase=node_prepare HOSTS=#{self.hostname}`
      `cd #{self.project_root} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment} deploy -S phase=node_prepare HOSTS=#{self.hostname}`
    end

    # Execute through capistrano the common development installation packages
    def prepare_common_installation
      `cd #{self.project_root} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment} deploy:prepare_installation:common -S phase=node_prepare HOSTS=#{self.hostname}`
    end

    # Execute through capistrano the puppet installation
    def puppet_installation
      `cd #{self.project_root} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment} deploy:prepare_installation:puppet -S phase=node_prepare HOSTS=#{self.hostname}`
    end

    # Create the checkpoints for the prepared nodes
    def create_prepare_checkpoint(started_at)
      self.started_at = started_at
      self.finished_at = DateTime.now.to_s
      generate_file_from_template("#{Bebox::FilesHelper::templates_path}/node/prepared_node.yml.erb", "#{self.project_root}/.checkpoints/environments/#{self.environment}/prepared_nodes/#{self.hostname}.yml", {node: self})
    end

    # Create the puppet hiera template file
    def create_hiera_template
      options = {ssh_key: Bebox::Project.public_ssh_key_from_file(project_root, environment), project_name: Bebox::Project.shortname_from_file(project_root)}
      Bebox::Provision.generate_hiera_for_steps(self.project_root, "node.yaml.erb", self.hostname, options)
    end

    # Create the node in the puppet manifests file
    def create_manifests_node
      Bebox::Provision.add_node_to_step_manifests(self.project_root, self)
    end

    # returns an Array of the Node objects for an environment
    # @returns Array
    def self.nodes_in_environment(project_root, environment, node_type)
      node_objects = []
      nodes = Bebox::Node.list(project_root, environment, node_type)
      nodes.each do |hostname|
        ip = Bebox::Node.checkpoint_parameter_from_file(project_root, environment, hostname, node_type, 'ip')
        node_objects << Bebox::Node.new(environment, project_root, hostname, ip)
      end
      node_objects
    end

    # Create checkpoint for node
    def create_node_checkpoint
      # Set the creation time for the node
      self.created_at = DateTime.now.to_s
      # Create the checkpoint file from template
      generate_file_from_template("#{Bebox::FilesHelper::templates_path}/node/node.yml.erb", "#{project_root}/.checkpoints/environments/#{environment}/nodes/#{hostname}.yml", {node: self})
    end

    # Remove checkpoints for node
    def remove_checkpoints
      `cd #{self.project_root} && rm -rf .checkpoints/environments/#{self.environment}/{nodes,prepared_nodes,steps/step-{0..3}}/#{self.hostname}.yml`
    end

    # Remove puppet hiera template file
    def remove_hiera_template
      Bebox::Provision.remove_hiera_for_steps(self.project_root, self.hostname)
    end

    # Remove node from puppet manifests
    def remove_manifests_node
      Bebox::Provision.remove_node_for_steps(self.project_root, self.hostname)
    end

    # Get the environments path for project
    def self.environments_path(project_root)
      "#{project_root}/.checkpoints/environments"
    end

    # Regenerate the deploy file for the environment
    def self.regenerate_deploy_file(project_root, environment, nodes)
      template_name = (environment == 'vagrant') ? 'vagrant' : "environment"
      generate_file_from_template("#{Bebox::FilesHelper::templates_path}/project/config/deploy/#{template_name}.erb", "#{project_root}/config/deploy/#{environment}.rb", {nodes: nodes, environment: environment})
    end

    # Count the number of prepared nodes
    def prepared_nodes_count
      Bebox::Node.list(self.project_root, self.environment, 'prepared_nodes').count
    end

    # Return a description string for the node provision state
    def self.node_provision_state(project_root, environment, node)
      provision_state = ''
      checkpoint_directories = %w{nodes prepared_nodes steps/step-0 steps/step-1 steps/step-2 steps/step-3}
      checkpoint_directories.each do |checkpoint_directory|
        checkpoint_directory_path = "#{project_root}/.checkpoints/environments/#{environment}/#{checkpoint_directory}/#{node}.yml"
        next unless File.exist?(checkpoint_directory_path)
        provision_state = "#{state_from_checkpoint(checkpoint_directory)} at #{Bebox::Node.node_creation_date(project_root, environment, checkpoint_directory, node)}"
      end
      provision_state
    end

    # Get the corresponding state from checkpoint directory
    def self.state_from_checkpoint(checkpoint)
      case checkpoint
        when 'nodes'
          'Allocated'
        when 'prepared_nodes'
          'Prepared'
        when 'steps/step-0'
          'Provisioned Fundamental step-0'
        when 'steps/step-1'
          'Provisioned Users layer step-1'
        when 'steps/step-2'
          'Provisioned Services layer step-2'
        when 'steps/step-3'
          'Provisioned Security layer step-3'
      end
    end

    # Obtain the node creation_at parameter for a node
    def self.node_creation_date(project_root, environment, node_type, node)
      node_config = YAML.load_file("#{project_root}/.checkpoints/environments/#{environment}/#{node_type}/#{node}.yml")
      (node_type == 'nodes') ? node_config['created_at'] : node_config['finished_at']
    end

    # Count the number of nodes in all environments
    def self.count_all_nodes_by_type(project_root, node_type)
      nodes_count = 0
      environments = Bebox::Environment.list(project_root)
      environments.each do |environment|
        nodes_count += Bebox::Node.list(project_root, environment, node_type).count
      end
      nodes_count
    end

    # Restore the previous local hosts file
    def restore_local_hosts(project_name)
      `sudo cp #{local_hosts_path}/hosts_before_#{project_name} #{local_hosts_path}/hosts`
      `sudo rm #{local_hosts_path}/hosts_before_#{project_name}`
    end
  end
end