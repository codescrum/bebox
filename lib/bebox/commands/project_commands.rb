
module Bebox
  module ProjectCommands

    include Bebox::CommandsHelper

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      load_environment_commands
      load_node_commands
      load_prepare_commands
      load_provision_commands
    end

    # Load environment commands
    def load_environment_commands
      self.extend Bebox::EnvironmentCommands
    end

    # Load node commands if there are environments configured
    def load_node_commands
       Bebox::Environment.list(project_root).count > 0 ? (self.extend Bebox::NodeCommands) : return
    end

    # Load prepare commands if there are at least one node
    def load_prepare_commands
      Bebox::Node.count_all_nodes_by_type(project_root, 'nodes') > 0 ? (self.extend Bebox::PrepareCommands) : return
    end

    # Load provision commands if there are nodes prepared
    def load_provision_commands
      Bebox::Node.count_all_nodes_by_type(project_root, 'prepared_nodes') > 0 ? (self.extend Bebox::ProvisionCommands) : return
    end
  end
end