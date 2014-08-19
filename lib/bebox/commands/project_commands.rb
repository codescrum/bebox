require 'bebox/commands/commands_helper'
require 'bebox/wizards/wizards_helper'

module Bebox
  module ProjectCommands

    include Bebox::CommandsHelper

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      require 'bebox/commands/environment_commands'
      require 'bebox/environment'
      self.extend Bebox::EnvironmentCommands
      # This commands only run if there are environments configured
      if Bebox::Environment.list(project_root).count > 0
        require 'bebox/commands/node_commands'
        self.extend Bebox::NodeCommands
        # These commands are available if there are at least one node configured in the project
        if Bebox::Node.count_all_nodes_by_type(project_root, 'nodes') > 0
          require 'bebox/commands/prepare_commands'
          self.extend Bebox::PrepareCommands
          # These commands are available if there are at least one prepared_node
          if Bebox::Node.count_all_nodes_by_type(project_root, 'prepared_nodes') > 0
            # load_provision_commands
            require 'bebox/commands/provision_commands'
            self.extend Bebox::ProvisionCommands
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