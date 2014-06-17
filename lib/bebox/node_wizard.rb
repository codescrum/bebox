require_relative 'node'
require 'highline/import'

module Bebox
  class NodeWizard

    # Create a new node
    def self.create_new_node(project_root, node_name)
      # Check if the node exist
      return "The node #{node_name} already exist!." if node_exists?(project_root, node_name)
      # Check if the node exist
      return "The node #{node_name} already exist!." if node_exists?(project_root, node_name)
      # Node creation
      node = Bebox::Node.new(node_name, project_root)
      node.create
      "Node created!."
    end

    # Removes an existing node
    def self.remove_node(project_root, node_name)
      # Check if the node exist
      return "The node #{node_name} don't exist!." unless node_exists?(project_root, node_name)
      # Confirm deletion
      return "Nothing done!." unless confirm_node_deletion?
      # Node deletion
      node = Bebox::Node.new(node_name, project_root)
      node.remove
      "Node removed!."
    end

    # Lists existing nodes
    def self.list_nodes(project_root, environment)
      Node.list(project_root, environment)
    end

    # Check if there's an existent node in the project
    def self.node_exists?(project_root, node_name)
      Dir.exists?("#{project_root}/.checkpoints/nodes/#{node_name}")
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
      environment = choose do |menu|
        menu.header = 'Choose an existent environment:'
        environments.each do |box|
          menu.choice(box.split('/').last)
        end
      end
      environment
    end
  end
end