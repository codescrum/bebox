
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
      ok 'Node created!.'
      return output
    end

    # Removes an existing node
    def remove_node(project_root, environment, hostname)
      # Ask for a node to remove
      nodes = Bebox::Node.list(project_root, environment, 'nodes')
      if nodes.count > 0
        hostname = choose_option(nodes, 'Choose the node to remove:')
      else
        error "There are no nodes in the '#{environment}' environment to remove. No changes were made."
        return true
      end
      # Ask for deletion confirmation
      return warn('No changes were made.') unless confirm_action?('Are you sure that you want to delete the node?')
      # Node deletion
      node = Bebox::Node.new(environment, project_root, hostname, nil)
      output = node.remove
      ok 'Node removed!.'
      return output
    end

    # Associate a role with a node in a environment
    def set_role(project_root, environment)
      roles = Bebox::Role.list(project_root)
      nodes = Bebox::Node.list(project_root, environment, 'nodes')
      node = choose_option(nodes, 'Choose an existing node:')
      role = choose_option(roles, 'Choose an existing role:')
      output = Bebox::Provision.associate_node_role(project_root, environment, node, role)
      ok 'Role associated to node!.'
      return output
    end

    # Prepare the nodes in a environment
    def prepare(project_root, environment)
      # Check already prepared nodes
      nodes_to_prepare = check_nodes_to_prepare(project_root, environment)
      # Output the nodes to be prepared
      if nodes_to_prepare.count > 0
        title 'Preparing nodes:'
        nodes_to_prepare.each{|node| msg(node.hostname)}
        linebreak
        # For all environments regenerate the deploy file
        Bebox::Node.regenerate_deploy_file(project_root, environment, nodes_to_prepare)
        # If environment is 'vagrant' Prepare and Up the machines
        if environment == 'vagrant'
          Bebox::VagrantHelper.generate_vagrantfile(nodes_to_prepare)
          nodes_to_prepare.each{|node| prepare_vagrant(node)}
          Bebox::VagrantHelper.up_vagrant_nodes(project_root)
        end
        # For all the environments do the preparation
        nodes_to_prepare.each do |node|
          node.prepare
          ok 'Node prepared!.'
        end
      else
        warn 'There are no nodes to prepare. No changes were made.'
      end
      return true
    end

    # Check the nodes already prepared and ask confirmation to re-do-it
    def check_nodes_to_prepare(project_root, environment)
      nodes_to_prepare = []
      nodes = Bebox::Node.nodes_in_environment(project_root, environment, 'nodes')
      prepared_nodes = Bebox::Node.list(project_root, environment, 'prepared_nodes')
      nodes.each do |node|
        if prepared_nodes.include?(node.hostname)
          checkpoint_status = "(start: #{node.checkpoint_parameter_from_file('prepared_nodes', 'started_at')} - end: #{node.checkpoint_parameter_from_file('prepared_nodes', 'finished_at')})"
          message = "The node '#{node.hostname}' was already prepared #{checkpoint_status}.\nDo you want to re-prepare it?"
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
        error 'A hostname with that name already exist. Try a new one.'
        ask_hostname(project_root, environment)
      else
        return hostname
      end
    end

    # Ask for the hostname
    def ask_hostname(project_root, environment)
      write_input('Write the hostname for the node:', nil, /\.(.*)/, 'Enter valid hostname. Ex. host.server1.com')
    end

    # Ask for the ip until is valid
    def ask_ip(environment)
      ip = write_input('Write the IP address for the node:', nil, /\.(.*)/, 'Enter a valid IP address. Ex. 192.168.0.50')
      # If the environment is not vagrant don't check ip free
      return ip if environment != 'vagrant'
      # Check if the ip address is free
      if free_ip?(ip)
        return ip
      else
        error 'The IP address is not free. Try a new one.'
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