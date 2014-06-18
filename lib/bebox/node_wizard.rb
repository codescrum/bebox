require_relative 'node'
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

    # Lists existing nodes in a environment
    def self.list_nodes(project_root, environment)
      Node.list(project_root, environment)
    end

    # Lists nodes for all environments
    def self.list_all_nodes(project_root)
      environments = Bebox::EnvironmentWizard.list_environments(project_root)
      environments.each do |environment|
        nodes = Node.list(project_root, environment)
        say("\nNodes for environment #{environment}:\n\n")
        nodes.map{|node| say(node)}
      end
      say("\n")
    end

    # Check if there's an existent node in a environment
    def self.node_exists?(project_root, environment, node_name)
      File.exists?("#{project_root}/.checkpoints/environments/#{environment}/nodes/#{node_name}.yml")
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