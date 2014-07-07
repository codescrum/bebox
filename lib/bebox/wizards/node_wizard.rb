require_relative '../node'
require 'highline/import'

module Bebox
  class NodeWizard

    # Create a new node
    def self.create_new_node(project_root, environment)
      # Ask the hostname for node
      hostname = ask_not_existing_hostname(project_root, environment)
      # Ask IP for node
      ip = ask_ip(environment)
      # Node creation
      node = Bebox::Node.new(environment, project_root, hostname, ip)
      node.create
      "Node created!."
    end

    # Removes an existing node
    def self.remove_node(project_root, environment, hostname)
      # Ask for a hostname/node to remove
      hostname = ask_existing_hostname(project_root, environment)
      # Confirm deletion
      return "Nothing done!." unless confirm_node_deletion?
      # Node deletion
      node = Bebox::Node.new(environment, project_root, hostname, nil)
      node.remove
      "Node removed!."
    end

    # Associate a role with a node in a environment
    def self.set_role(project_root, environment)
      roles = Bebox::Role.list(project_root)
      nodes = Bebox::Node.list(project_root, environment, 'nodes')
      node = Bebox::NodeWizard.choose_node(nodes)
      role = Bebox::RoleWizard.choose_role(roles)
      Bebox::Puppet.associate_node_role(project_root, environment, node, role)
    end

    # Prepare the nodes in a environment
    def self.prepare(project_root, environment)
      # Check already prepared nodes
      nodes_to_prepare = check_nodes_to_prepare(project_root, environment)
      # Output the nodes to be prepared
      if nodes_to_prepare.count > 0
        say("\nPreparing nodes: \n")
        nodes_to_prepare.each{|node| say(node.hostname)}
        say("\n")
        # For all environments regenerate the deploy file
        Bebox::Node.regenerate_deploy_file(project_root, environment, nodes_to_prepare)
        # If environment is 'vagrant' Prepare and Up the machines
        if environment == 'vagrant'
          Bebox::Node.generate_vagrantfile(project_root, nodes_to_prepare)
          nodes_to_prepare.each{|node| node.prepare_vagrant}
          Bebox::Node.up_vagrant_nodes(project_root)
        end
        # For all the environments do the preparation
        nodes_to_prepare.each{|node| node.prepare}
      else
        say("\nThere are no nodes to prepare. Nothing done.\n\n")
      end

    end

    # Check the nodes already prepared and ask confirmation to re-do-it
    def self.check_nodes_to_prepare(project_root, environment)
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
    def self.node_exists?(project_root, environment, node_name)
      File.exists?("#{project_root}/.checkpoints/environments/#{environment}/nodes/#{node_name}.yml")
    end

    # Ask for confirmation of node preparation
    def self.confirm_node_preparation?(node)
      say("The node #{node.hostname} is already prepared. Do you want to re-prepare it?")
      response =  ask("(y/n)")do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Ask for confirmation of node deletion
    def self.confirm_node_deletion?
      say('Are you sure that you want to delete the node?')
      response =  ask("(y/n)")do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Asks to choose an existent environment
    def self.choose_environment(environments)
      choose do |menu|
        menu.header = 'Choose an existent environment:'
        environments.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end

    # Asks to choose an existent node
    def self.choose_node(nodes)
      choose do |menu|
        menu.header = 'Choose an existent node:'
        nodes.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end

    # Keep asking for a hostname that not exist
    def self.ask_not_existing_hostname(project_root, environment)
      hostname = ask_hostname(project_root, environment)
      # Check if the node not exist
      if node_exists?(project_root, environment, hostname)
        say("A hostname with that name already exist!. Try a new one.")
        say("\n")
        ask_hostname(project_root, environment)
      else
        return hostname
      end
    end

    # Keep asking for a hostname that exist
    def self.ask_existing_hostname(project_root, environment)
      hostname = ask_hostname(project_root, environment)
      # Check if the node exist
      if node_exists?(project_root, environment, hostname)
        return hostname
      else
        say("The node #{hostname} don't exist!. Try a new one.")
        ask_hostname(project_root, environment)
      end
    end

    # Ask for the hostname until is valid
    def self.ask_hostname(project_root, environment)
      ask("Write the hostname for the node:") do |q|
        q.validate = /\.(.*)/
        q.responses[:not_valid] = "Enter valid hostname. Ex. host.server1.com"
      end
    end

    # Ask for the ip until is valid
    def self.ask_ip(environment)
      ip = ask("Write the IP address for the node:") do |q|
        q.validate = /\.(.*)/
        q.responses[:not_valid] = "Enter a valid IP address. Ex. 192.168.0.50"
      end
      # If the environment is not vagrant don't check ip free
      return ip if environment != 'vagrant'
      # Check if the ip address is free
      if free_ip?(ip)
        return ip
      else
        say("The IP address is not free!. Try a new one.")
        say("\n")
        ask_ip(environment)
      end
    end

    # Validate if the IP address is free
    def self.free_ip?(ip)
      `ping -q -c 1 -W 3000 #{ip}`
      ($?.exitstatus == 0) ? false : true
    end
  end
end