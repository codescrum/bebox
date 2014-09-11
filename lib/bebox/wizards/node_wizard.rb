
module Bebox
  class NodeWizard
    include Bebox::Logger
    include Bebox::WizardsHelper
    include Bebox::VagrantHelper

    # Create a new node
    def create_new_node(project_root, environment)
      # Ask the hostname for node
      hostname = ask_not_existing_hostname(project_root, environment)
      # Ask IP for node
      ip = ask_ip(environment)
      # Node creation
      node = Bebox::Node.new(environment, project_root, hostname, ip)
      output = node.create
      ok _('wizard.node.creation_success')
      return output
    end

    # Removes an existing node
    def remove_node(project_root, environment, hostname)
      # Ask for a node to remove
      nodes = Bebox::Node.list(project_root, environment, 'nodes')
      if nodes.count > 0
        hostname = choose_option(nodes, _('wizard.node.choose_node'))
      else
        error _('wizard.node.no_nodes')%{environment: environment}
        return true
      end
      # Ask for deletion confirmation
      return warn(_('wizard.no_changes')) unless confirm_action?(_('wizard.node.confirm_deletion'))
      # Node deletion
      node = Bebox::Node.new(environment, project_root, hostname, nil)
      output = node.remove
      ok _('wizard.node.deletion_success')
      return output
    end

    # Associate a role with a node in a environment
    def set_role(project_root, environment)
      roles = Bebox::Role.list(project_root)
      nodes = Bebox::Node.list(project_root, environment, 'nodes')
      node = choose_option(nodes, _('wizard.choose_node'))
      role = choose_option(roles, _('wizard.choose_role'))
      output = Bebox::Provision.associate_node_role(project_root, environment, node, role)
      ok _('wizard.node.role_set_success')
      return output
    end

    # Prepare the nodes in a environment
    def prepare(project_root, environment)
      # Check already prepared nodes
      nodes_to_prepare = check_nodes_to_prepare(project_root, environment)
      # Output the nodes to be prepared
      if nodes_to_prepare.count > 0
        title _('wizard.node.prepare_title')
        nodes_to_prepare.each{|node| msg(node.hostname)}
        linebreak
        # For all environments regenerate the deploy file
        Bebox::Node.regenerate_deploy_file(project_root, environment, nodes_to_prepare)
        # If environment is 'vagrant' Prepare and Up the machines
        up_vagrant_machines(project_root, nodes_to_prepare) if environment == 'vagrant'
        # For all the environments do the preparation
        nodes_to_prepare.each do |node|
          node.prepare
          ok _('wizard.node.preparation_success')
        end
      else
        warn _('wizard.node.no_prepare_nodes')
      end
      return true
    end

    def up_vagrant_machines(project_root, nodes_to_prepare)
      Bebox::VagrantHelper.generate_vagrantfile(nodes_to_prepare)
      nodes_to_prepare.each{|node| prepare_vagrant(node)}
      Bebox::VagrantHelper.up_vagrant_nodes(project_root)
    end

    # Check the nodes already prepared and ask confirmation to re-do-it
    def check_nodes_to_prepare(project_root, environment)
      nodes_to_prepare = []
      nodes = Bebox::Node.nodes_in_environment(project_root, environment, 'nodes')
      prepared_nodes = Bebox::Node.list(project_root, environment, 'prepared_nodes')
      nodes.each do |node|
        if prepared_nodes.include?(node.hostname)
          message = _('wizard.node.confirm_preparation')%{hostname: node.hostname, start: node.checkpoint_parameter_from_file('prepared_nodes', 'started_at'), end: node.checkpoint_parameter_from_file('prepared_nodes', 'finished_at')}
          nodes_to_prepare << node if confirm_action?(message)
        else
          nodes_to_prepare << node
        end
      end
      nodes_to_prepare
    end

    # Check if there's an existing node in a environment
    def node_exists?(project_root, environment, node_name)
      File.exists?("#{project_root}/.checkpoints/environments/#{environment}/nodes/#{node_name}.yml")
    end

    # Keep asking for a hostname that not exist
    def ask_not_existing_hostname(project_root, environment)
      hostname = ask_hostname(project_root, environment)
      # Check if the node not exist
      if node_exists?(project_root, environment, hostname)
        error _('wizard.node.hostname_exist')
        ask_hostname(project_root, environment)
      else
        return hostname
      end
    end

    # Ask for the hostname
    def ask_hostname(project_root, environment)
      write_input(_('wizard.node.ask_hostname'), nil, /\.(.*)/, _('wizard.node.valid_hostname'))
    end

    # Ask for the ip until is valid
    def ask_ip(environment)
      ip = write_input(_('wizard.node.ask_ip'), nil, /\.(.*)/, _('wizard.node.valid_ip'))
      # If the environment is not vagrant don't check ip free
      return ip if environment != 'vagrant'
      # Check if the ip address is free
      if free_ip?(ip)
        return ip
      else
        error _('wizard.node.non_free_ip')
        ask_ip(environment)
      end
    end

    # Validate if the IP address is free
    def free_ip?(ip)
      `ping -q -c 1 -W 3000 #{ip}`
      ($?.exitstatus == 0) ? false : true
    end
  end
end