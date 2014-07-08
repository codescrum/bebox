require_relative '../node'
require 'highline/import'
require 'bebox/logger'

module Bebox
  class NodeWizard
    include Bebox::Logger
    # Create a new node
    def create_new_node(project_root, environment)
      # Ask the hostname for node
      hostname = ask_not_existing_hostname(project_root, environment)
      # Ask IP for node
      ip = ask_ip(environment)
      # Node creation
      node = Bebox::Node.new(environment, project_root, hostname, ip)
      node.create
      ok 'Node created!.'
    end

    # Removes an existing node
    def remove_node(project_root, environment, hostname)
      # Ask for a hostname/node to remove
      hostname = ask_existing_hostname(project_root, environment)
      # Confirm deletion
      return warn('Nothing done!.') unless confirm_node_deletion?
      # Node deletion
      node = Bebox::Node.new(environment, project_root, hostname, nil)
      node.remove
      ok 'Node removed!.'
    end

    # Associate a role with a node in a environment
    def set_role(project_root, environment)
      roles = Bebox::Role.list(project_root)
      nodes = Bebox::Node.list(project_root, environment, 'nodes')
      node = choose_node(nodes)
      role = Bebox::RoleWizard.new.choose_role(roles)
      Bebox::Puppet.associate_node_role(project_root, environment, node, role)
      ok 'Role associated to node!.'
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
          Bebox::Node.generate_vagrantfile(project_root, nodes_to_prepare)
          nodes_to_prepare.each{|node| node.prepare_vagrant}
          Bebox::Node.up_vagrant_nodes(project_root)
        end
        # For all the environments do the preparation
        nodes_to_prepare.each do |node|
          node.prepare
          ok 'Node prepared!.'
        end

      else
        warn 'There are no nodes to prepare. Nothing done.'
      end
    end

    # Check the nodes already prepared and ask confirmation to re-do-it
    def check_nodes_to_prepare(project_root, environment)
      nodes_to_prepare = []
      nodes = Bebox::Node.nodes_in_environment(project_root, environment, 'nodes')
      prepared_nodes = Bebox::Node.list(project_root, environment, 'prepared_nodes')
      nodes.each do |node|
        if prepared_nodes.include?(node.hostname)
          nodes_to_prepare << node if confirm_node_preparation?(node)
        else
          nodes_to_prepare << node
        end
      end
      nodes_to_prepare
    end

    # Check if there's an existent node in a environment
    def node_exists?(project_root, environment, node_name)
      File.exists?("#{project_root}/.checkpoints/environments/#{environment}/nodes/#{node_name}.yml")
    end

    # Ask for confirmation of node preparation
    def confirm_node_preparation?(node)
      quest "The node #{node.hostname} is already prepared. Do you want to re-prepare it?"
      response =  ask(highline_quest('(y/n)')) do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Ask for confirmation of node deletion
    def confirm_node_deletion?
      quest 'Are you sure that you want to delete the node?'
      response =  ask(highline_quest('(y/n)')) do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Asks to choose an existent node
    def choose_node(nodes)
      choose do |menu|
        menu.header = title('Choose an existent node:')
        nodes.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end

    # Keep asking for a hostname that not exist
    def ask_not_existing_hostname(project_root, environment)
      hostname = ask_hostname(project_root, environment)
      # Check if the node not exist
      if node_exists?(project_root, environment, hostname)
        error 'A hostname with that name already exist!. Try a new one.'
        ask_hostname(project_root, environment)
      else
        return hostname
      end
    end

    # Keep asking for a hostname that exist
    def ask_existing_hostname(project_root, environment)
      hostname = ask_hostname(project_root, environment)
      # Check if the node exist
      if node_exists?(project_root, environment, hostname)
        return hostname
      else
        error "The node #{hostname} don't exist!. Try a new one."
        ask_hostname(project_root, environment)
      end
    end

    # Ask for the hostname until is valid
    def ask_hostname(project_root, environment)
      ask(highline_quest('Write the hostname for the node:')) do |q|
        q.validate = /\.(.*)/
        q.responses[:not_valid] = highline_warn('Enter valid hostname. Ex. host.server1.com')
      end
    end

    # Ask for the ip until is valid
    def ask_ip(environment)
      ip = ask(highline_quest('Write the IP address for the node:')) do |q|
        q.validate = /\.(.*)/
        q.responses[:not_valid] = highline_warn('Enter a valid IP address. Ex. 192.168.0.50')
      end
      # If the environment is not vagrant don't check ip free
      return ip if environment != 'vagrant'
      # Check if the ip address is free
      if free_ip?(ip)
        return ip
      else
        error 'The IP address is not free!. Try a new one.'
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