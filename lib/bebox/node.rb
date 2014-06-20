require 'tilt'
require 'pry'

module Bebox
  class Node

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
    end

    # Delete all files and directories related to an node
    def remove
      remove_checkpoint
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
      puts "  Adding server to vagrant: #{self.hostname}..."
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
      puts 'Please provide your account password, if ask you, to configure the local hosts file.'
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

    # Remove checkpoint for node
    def remove_checkpoint
      `cd #{self.project_root} && rm -rf .checkpoints/environments/#{self.environment}/{nodes,prepared-nodes,steps/step-{0..3}}/#{self.hostname}.yml`
    end

    # Get the templates path inside the gem
    def self.templates_path
      # File.expand_path(File.join(File.dirname(__FILE__), "..", "gems/bundler/lib/templates"))
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
        f.write config_deploy_template.render(nil, :nodes => nodes)
      end
    end

    # return an String with the status of vagrant boxes
    # @returns String
    def self.vagrant_nodes_status(project_root)
      `cd #{project_root} && vagrant status`
    end

    # Install the common development dependecies with capistrano prepare (phase 4)
    # def install_common_dev
    #   config_initial_puppet
    #   `cd #{self.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{name} deploy:prepare_common_dev -s phase='common_dev'`
    # end

    # def config_initial_puppet
    #   config_initial_hiera
    #   config_manifests
    # end

    # def config_initial_hiera
    #   hiera_template = Tilt::ERBTemplate.new("templates/initial_puppet/hiera/hiera.yaml.erb")
    #   File.open("#{self.project.path}/initial_puppet/hiera/hiera.yaml", 'w') do |f|
    #     f.write hiera_template.render(nil)
    #   end
    #   common_hiera_template = Tilt::ERBTemplate.new("templates/initial_puppet/hiera/data/common.yaml.erb")
    #   ssh_puppet_key = File.read("#{self.project.path}/keys/puppet.rsa.pub")
    #   File.open("#{self.project.path}/initial_puppet/hiera/data/common.yaml", 'w') do |f|
    #     f.write common_hiera_template.render(self, :puppet_key => ssh_puppet_key)
    #   end
    # end

    # def config_manifests
    #   `cp templates/initial_puppet/manifests/site.pp #{self.project.path}/initial_puppet/manifests`
    #   `cp -r templates/initial_puppet/modules/* #{self.project.path}/initial_puppet/modules`
    # end

    # # Remove the specified boxes from vagrant
    # def remove_vagrant_boxes
    #   self.project.servers.size.times do |i|
    #     `cd #{self.project.path} && vagrant destroy -f node_#{i}`
    #     `cd #{self.project.path} && vagrant box remove #{self.project.vagrant_box_base_name}_#{i} #{self.project.vagrant_box_provider}`
    #   end
    # end

    # # return an String with the status of vagrant boxes
    # # @returns String
    # def vagrant_nodes_status
    #   `cd #{self.project.path} && vagrant status`
    # end

    # # Restore the previous local hosts file
    # def restore_local_hosts
    #   `sudo cp #{self.hosts_backup_file} #{self.local_hosts_path}/hosts`
    #   `sudo rm #{self.hosts_backup_file}`
    #   self.hosts_backup_file = ''
    # end
  end
end