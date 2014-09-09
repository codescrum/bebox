
module Bebox
  module NodeCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      # Nodes management phase commands
      desc _('cli.node.desc')
      command :node do |node_command|
        node_list_command(node_command)
        generate_node_command(node_command, :new, :create_new_node, _('cli.node.new.desc'))
        node_remove_command(node_command)
        # These commands are available if there is at least one role and one node
        generate_node_command(node_command, :set_role, :set_role, _('cli.node.set_role.desc')) if (Bebox::Role.roles_count(project_root) > 0 && Bebox::Node.count_all_nodes_by_type(project_root, 'phase-0') > 0)
      end
    end

    def node_list_command(node_command)
      # Node list command
      node_command.flag :environment, desc: _('cli.node.list.env_flag_desc'), default_value: default_environment
      node_command.desc _('cli.node.list.desc')
      node_command.command :list do |node_list_command|
        node_list_command.switch :all
        node_list_command.action do |global_options,options,args|
          # Call to list nodes
          environments = options[:all] ? Bebox::Environment.list(project_root) : [get_environment(options)]
          list_environments(environments)
          linebreak
        end
      end
    end

    # For new and set_role commands
    def generate_node_command(node_command, command, send_command, description)
      node_command.desc description
      node_command.command command do |generated_command|
        generated_command.action do |global_options,options,args|
          environment = get_environment(options)
          info _('cli.current_environment')%{environment: environment}
          Bebox::NodeWizard.new.send(send_command, project_root, environment)
        end
      end
    end

    def node_remove_command(node_command)
      node_command.desc _('cli.node.remove.desc')
      node_command.command :remove do |node_remove_command|
        node_remove_command.action do |global_options,options,args|
          environment = get_environment(options)
          info _('cli.current_environment')%{environment: environment}
          Bebox::NodeWizard.new.remove_node(project_root, environment, args.first)
        end
      end
    end

    def list_environments(environments)
      environments.each do |environment|
        nodes = Node.list(project_root, environment, 'phase-0')
        title _('cli.node.list.env_nodes_title')%{environment: environment}
        nodes.map{|node| msg("#{node}     (#{Bebox::Node.node_provision_state(project_root, environment, node)})")}
        warn(_('cli.node.list.no_nodes')) if nodes.empty?
      end
    end
  end
end