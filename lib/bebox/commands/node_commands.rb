require 'bebox/role'
require 'bebox/node'
require 'bebox/wizards/node_wizard'

module Bebox
  module NodeCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      # Nodes management phase commands
      desc 'Manage nodes for a environment in the project.'
      command :node do |node_command|
        node_list_command(node_command)
        generate_node_command(node_command, :new, :create_new_node, 'Add a node to a environment')
        node_remove_command(node_command)
        # These commands are available if there is at least one role and one node
        generate_node_command(node_command, :set_role, :set_role, 'Associate a node with a role in a environment') if (Bebox::Role.roles_count(project_root) > 0 && Bebox::Node.count_all_nodes_by_type(project_root, 'nodes') > 0)
      end
    end

    def node_list_command(node_command)
      # Node list command
      node_command.flag :environment, desc: 'Set the environment for nodes', default_value: default_environment
      node_command.desc 'list the nodes in a environment'
      node_command.command :list do |node_list_command|
        node_list_command.switch :all
        node_list_command.action do |global_options,options,args|
          # Call to list nodes
          environments = options[:all] ? Bebox::Environment.list(project_root) : [get_environment(options)]
          environments.each do |environment|
            nodes = Node.list(project_root, environment, 'nodes')
            title "Nodes for '#{environment}' environment:"
            nodes.map{|node| msg("#{node}     (#{Bebox::Node.node_provision_state(project_root, environment, node)})")}
            warn('There are not nodes yet in the environment. You can create a new one with: \'bebox node new\' command.') if nodes.empty?
          end
          linebreak
        end
      end
    end

    def generate_node_command(node_command, command, send_command, description)
      node_command.desc description
      node_command.command command do |command|
        command.action do |global_options,options,args|
          environment = get_environment(options)
          info "Environment: #{environment}"
          Bebox::NodeWizard.new.send(send_command, project_root, environment)
        end
      end
    end

    # def node_new_command(node_command)
    #   # Node new command
    #   node_command.desc 'add a node to a environment'
    #   node_command.command :new do |node_new_command|
    #     node_new_command.action do |global_options,options,args|
    #       node_command_action(:create_node, options)
    #     end
    #   end
    # end

    def node_remove_command(node_command)
      # Node remove command
      node_command.desc "remove a node in a environment"
      node_command.command :remove do |node_remove_command|
        node_remove_command.action do |global_options,options,args|
          environment = get_environment(options)
          info "Environment: #{environment}"
          Bebox::NodeWizard.new.remove_node(project_root, environment, args.first)
        end
      end
    end

    # def node_set_role_command(node_command)
    #   # Associate node to role command
    #   node_command.desc "Associate a node with a role in a environment"
    #   node_command.command :set_role do |node_role_command|
    #     node_role_command.action do |global_options,options,args|
    #       node_command_action(:set_role, options)
    #     end
    #   end
    # end
  end
end