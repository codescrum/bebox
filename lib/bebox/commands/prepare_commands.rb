require 'bebox/commands/commands_helper'

module Bebox
  module PrepareCommands
    def load_prepare_commands
      # Prepare nodes phase commands
      desc 'Prepare the nodes for the environment.'
      command :prepare do |prepare_command|
        prepare_command.flag :environment, :desc => 'Set the environment of node', default_value: default_environment
        prepare_command.action do |global_options,options,args|
          environment = get_environment(options)
          # Check if vagrant is installed
          return 'Vagrant is not installed in the system. Nothing done.' unless vagrant_installed?
          say("\nEnvironment #{environment}.\n")
          Bebox::NodeWizard.prepare(project_root, environment)
        end
      end
      # These commands are available if there are at least one node in the vagrant environment
      if Bebox::Node.list(project_root, 'vagrant', 'nodes').count > 0
        desc 'Halt the nodes for vagrant environment.'
        command :vagrant_halt do |vagrant_halt_command|
          vagrant_halt_command.action do |global_options,options,args|
            # Check if vagrant is installed
            return 'Vagrant is not installed in the system. Nothing done.' unless vagrant_installed?
            # List nodes in environment and notice message
            nodes = Bebox::Node.nodes_in_environment(project_root, 'vagrant', 'nodes')
            environment = 'vagrant'
            say("\nEnvironment #{environment}.\n")
            say("\nHalting nodes: \n")
            nodes.each{|node| say(node.hostname)}
            say("\n")
            # Halt vagrant nodes
            Bebox::Node.halt_vagrant_nodes(project_root)
          end
        end
        desc 'Up the nodes for vagrant environment.'
        command :vagrant_up do |vagrant_up_command|
          vagrant_up_command.action do |global_options,options,args|
            # Check if vagrant is installed
            return 'Vagrant is not installed in the system. Nothing done.' unless vagrant_installed?
            # List nodes in environment and notice message
            nodes = Bebox::Node.nodes_in_environment(project_root, 'vagrant', 'nodes')
            environment = 'vagrant'
            say("\nEnvironment #{environment}.\n")
            say("\nRunning up nodes: \n")
            nodes.each{|node| say(node.hostname)}
            say("\n")
            # Up vagrant nodes
            Bebox::Node.up_vagrant_nodes(project_root)
          end
        end
      end
    end
  end
end