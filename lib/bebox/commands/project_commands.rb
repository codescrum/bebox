require 'bebox/commands/environment_commands'
require 'bebox/commands/node_commands'
require 'bebox/commands/prepare_commands'
require 'bebox/commands/provision_commands'

module Bebox
  module ProjectCommands

    include Bebox::EnvironmentCommands
    include Bebox::NodeCommands
    include Bebox::PrepareCommands
    include Bebox::ProvisionCommands
    include Bebox::CommandsHelper

    def load_project_commands
      load_environment_commands
      # This commands only run if there are environments configured
      if Bebox::Environment.list(project_root).count > 0
        load_node_commands
        # These commands are available if there are at least one node configured in the project
        if Bebox::Node.count_all_nodes_by_type(project_root, 'nodes') > 0
          load_prepare_commands
          # These commands are available if there are at least one prepared_node
          if Bebox::Node.count_all_nodes_by_type(project_root, 'prepared_nodes') > 0
            load_provision_commands
          end
        end
      end
      pre do |global_options,command,options,args|
        true
      end

      post do |global_options,command,options,args|
      end

      on_error do |exception|
        true
      end
    end
  end
end