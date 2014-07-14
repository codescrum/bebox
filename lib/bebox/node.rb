require 'tilt'
require 'bebox/logger'

module Bebox
  class Node

    include Bebox::Logger

    attr_accessor :environment, :project_root, :hostname, :ip

    def initialize(environment, project_root, hostname, ip)
      self.environment = environment
      self.project_root = project_root
      self.hostname = hostname
      self.ip = ip
    end

    # Create all files and directories related to an node
    def create
      create_node_checkpoint
      create_hiera_template
      create_manifests_node
    end

    # Delete all files and directories related to an node
    def remove
      remove_vagrant_box if self.environment == 'vagrant' && prepared_nodes_count > 0
      remove_checkpoints
      remove_hiera_template
      remove_manifests_node
    end

    # List existing nodes for environment and type (nodes, prepared_nodes)
    def self.list(project_root, environment, node_type)
      Dir["#{environments_path(project_root)}/#{environment}/#{node_type}/*"].map { |f| File.basename(f, ".*") }
    end

    # Get IP of node from the yml file
    def self.ip_from_file(project_root, environment, hostname)
      node_config = YAML.load_file("#{environments_path(project_root)}/#{environment}/nodes/#{hostname}.yml")
      node_config['ip']
    end

    # Prepare the configured nodes
    def prepare
      prepare_deploy
      prepare_common_installation
      puppet_installation
      create_prepare_checkpoint
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
    def create_prepare_checkpoint
      node_template = Tilt::ERBTemplate.new("#{Bebox::Node::templates_path}/node/node.yml.erb")
      File.open("#{self.project_root}/.checkpoints/environments/#{self.environment}/prepared_nodes/#{self.hostname}.yml", 'w') do |f|
        f.write node_template.render(nil, :node => self)
      end
    end

    # Create the puppet hiera template file
    def create_hiera_template
      options = {}
      options[:ssh_key] = Bebox::Project.public_ssh_key_from_file(self.project_root, self.environment)
      options[:project_name] = Bebox::Project.name_from_file(self.project_root)
      Bebox::Puppet.generate_hiera_for_steps(self.project_root, "node.yaml.erb", self.hostname, options)
    end

    # Create the node in the puppet manifests file
    def create_manifests_node
      Bebox::Puppet.add_node_to_step_manifests(self.project_root, self)
    end

    # Prepare the vagrant nodes
    def prepare_vagrant
      project_name = Bebox::Project.name_from_file(self.project_root)
      vagrant_box_base = Bebox::Project.vagrant_box_base_from_file(self.project_root)
      configure_local_hosts(project_name)
      add_vagrant_node(project_name, vagrant_box_base)
    end

    # Add the boxes to vagrant for each node
    def add_vagrant_node(project_name, vagrant_box_base)
      already_installed_boxes = installed_vagrant_box_names
      box_name = "#{project_name}-#{self.hostname}"
      info "Adding server to vagrant: #{self.hostname}..."
      `cd #{self.project_root} && vagrant box add #{box_name} #{vagrant_box_base}` unless already_installed_boxes.include? box_name
    end

    # Up the vagrant boxes in Vagrantfile
    def self.up_vagrant_nodes(project_root)
      `cd #{project_root} && vagrant up --provision`
    end

    # Halt the vagrant boxes running
    def self.halt_vagrant_nodes(project_root)
      `cd #{project_root} && vagrant halt`
    end

    # return an Array with the names of the currently installed vagrant boxes
    # @returns Array
    def installed_vagrant_box_names
      (`cd #{self.project_root} && vagrant box list`).split("\n").map{|vagrant_box| vagrant_box.split(' ').first}
    end

    # returns an Array of the Node objects for an environment
    # @returns Array
    def self.nodes_in_environment(project_root, environment, node_type)
      node_objects = []
      nodes = Bebox::Node.list(project_root, environment, node_type)
      nodes.each do |hostname|
        ip = Bebox::Node.ip_from_file(project_root, environment, hostname)
        node_objects << Bebox::Node.new(environment, project_root, hostname, ip)
      end
      node_objects
    end

    # Generate the Vagrantfile
    def self.generate_vagrantfile(project_root, nodes)
      template = Tilt::ERBTemplate.new("#{templates_path}/node/Vagrantfile.erb")
      network_interface = RUBY_PLATFORM =~ /darwin/ ? 'en0' : 'eth0'
      project_name = Bebox::Project.name_from_file(project_root)
      vagrant_box_provider = Bebox::Project.vagrant_box_provider_from_file(project_root)
      File.open("#{project_root}/Vagrantfile", 'w') do |f|
        f.write template.render(nil, :nodes => nodes, :project_name => project_name,
          :vagrant_box_provider => vagrant_box_provider, :network_interface => network_interface)
      end
    end

    # Backup and add the vagrant hosts to local hosts file
    def configure_local_hosts(project_name)
      info "\nPlease provide your account password, if ask you, to configure the local hosts file."
      backup_local_hosts(project_name)
      add_to_local_hosts
    end

    # Add the vagrant hosts to the local hosts file
    def add_to_local_hosts
      # Get the content of the hosts file
      hosts_content = File.read("#{local_hosts_path}/hosts").gsub(/\s+/, ' ').strip
      # Put the node lines in hosts file if not exist
      line = "#{self.ip} #{self.hostname}"
      node_present = (hosts_content =~ /#{self.ip}\s+#{self.hostname}/) ? true : false
      `sudo echo '#{line}     # Added by bebox' | sudo tee -a #{local_hosts_path}/hosts` unless node_present
    end

    # Backup the local hosts file
    def backup_local_hosts(project_name)
      # Make a backup of hosts file
      hosts_backup_file = "#{local_hosts_path}/hosts_before_bebox_#{project_name}"
      `sudo cp #{local_hosts_path}/hosts #{hosts_backup_file}` unless File.exist?(hosts_backup_file)
    end

    # Obtain the local hosts file for the OS
    def local_hosts_path
      RUBY_PLATFORM =~ /darwin/ ? '/private/etc' : '/etc'
    end

    # Create checkpoint for node
    def create_node_checkpoint

      node_template = Tilt::ERBTemplate.new("#{Bebox::Node::templates_path}/node/node.yml.erb")
      File.open("#{self.project_root}/.checkpoints/environments/#{self.environment}/nodes/#{self.hostname}.yml", 'w') do |f|
        f.write node_template.render(nil, :node => self)
      end
    end

    # Remove checkpoints for node
    def remove_checkpoints
      `cd #{self.project_root} && rm -rf .checkpoints/environments/#{self.environment}/{nodes,prepared_nodes,steps/step-{0..3}}/#{self.hostname}.yml`
    end

    # Remove puppet hiera template file
    def remove_hiera_template
      Bebox::Puppet.remove_hiera_for_steps(self.project_root, self.hostname)
    end

    # Remove node from puppet manifests
    def remove_manifests_node
      Bebox::Puppet.remove_node_for_steps(self.project_root, self.hostname)
    end

    # Remove the specified boxes from vagrant
    def remove_vagrant_box
      project_name = Bebox::Project.name_from_file(self.project_root)
      vagrant_box_provider = Bebox::Project.vagrant_box_provider_from_file(self.project_root)
      `cd #{self.project_root} && vagrant destroy -f #{self.hostname}`
      `cd #{self.project_root} && vagrant box remove #{project_name}-#{self.hostname} #{vagrant_box_provider}`
    end

    # Get the templates path inside the gem
    def self.templates_path
      File.join((File.expand_path '..', File.dirname(__FILE__)), 'templates')
    end

    # Get the environments path for project
    def self.environments_path(project_root)
      "#{project_root}/.checkpoints/environments"
    end

    # Regenerate the deploy file for the environment
    def self.regenerate_deploy_file(project_root, environment, nodes)
      template_name = (environment == 'vagrant') ? 'vagrant' : "environment"
      config_deploy_template = Tilt::ERBTemplate.new("#{templates_path}/project/config/deploy/#{template_name}.erb")
      File.open("#{project_root}/config/deploy/#{environment}.rb", 'w') do |f|
        f.write config_deploy_template.render(nil, :nodes => nodes, :environment => environment)
      end
    end

    # return an String with the status of vagrant boxes
    # @returns String
    def self.vagrant_nodes_status(project_root)
      `cd #{project_root} && vagrant status`
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
        provision_state = state_from_checkpoint(checkpoint_directory) if File.exist?(checkpoint_directory_path)
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

    # Count the number of nodes in all environments
    def self.count_all_nodes_by_type(project_root, node_type)
      nodes_count = 0
      environments = Bebox::Environment.list(project_root)
      environments.each do |environment|
        nodes_count += Bebox::Node.list(project_root, environment, node_type).count
      end
      nodes_count
    end

    # # Restore the previous local hosts file
    # def restore_local_hosts
    #   `sudo cp #{self.hosts_backup_file} #{self.local_hosts_path}/hosts`
    #   `sudo rm #{self.hosts_backup_file}`
    #   self.hosts_backup_file = ''
    # end
  end
end