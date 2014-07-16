require 'bebox/role'
require 'bebox/node'

module Bebox
  module NodeCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      # Nodes management phase commands
      desc 'Manage nodes for a environment in the project.'
      command :node do |node_command|
        # Node list command
        node_command.flag :environment, :desc => 'Set the environment of nodes', default_value: default_environment
        node_command.desc 'list the nodes in a environment'
        node_command.command :list do |node_list_command|
          node_list_command.switch :all
          node_list_command.action do |global_options,options,args|
            # Call to list nodes
            environments = options[:all] ? Bebox::Environment.list(project_root) : [get_environment(options)]
            environments.each do |environment|
              nodes = Node.list(project_root, environment, 'nodes')
              title "Nodes for environment #{environment}:"
              nodes.map{|node| msg("#{node}     (#{Bebox::Node.node_provision_state(project_root, environment, node)})")}
              warn('There are not nodes yet in the environment. You can create a new one with: \'bebox node new\' command.') if nodes.empty?
            end
            linebreak
          end
        end
        # Node new command
        node_command.desc 'add a node to a environment'
        node_command.command :new do |node_new_command|
          node_new_command.action do |global_options,options,args|
            environment = get_environment(options)
            info "Environment #{environment}."
            require 'bebox/wizards/node_wizard'
            Bebox::NodeWizard.new.create_new_node(project_root, environment)
          end
        end
        # Node remove command
        node_command.desc "remove a node in a environment"
        node_command.command :remove do |node_remove_command|
          node_remove_command.action do |global_options,options,args|
            environment = get_environment(options)
            info "Environment #{environment}."
            require 'bebox/wizards/node_wizard'
            Bebox::NodeWizard.new.remove_node(project_root, environment, args.first)
          end
        end
        # These commands are available if there is at least one role and one node
        if Bebox::Role.roles_count(project_root) > 0 && Bebox::Node.count_all_nodes_by_type(project_root, 'nodes') > 0
          # Associate node to role command
          node_command.desc "Associate a node with a role in a environment"
          node_command.command :set_role do |node_role_command|
            node_role_command.action do |global_options,options,args|
              environment = get_environment(options)
              info "Environment #{environment}."
              require 'bebox/wizards/node_wizard'
              Bebox::NodeWizard.new.set_role(project_root, environment)
            end
          end
        end
      end
    end
  end
end