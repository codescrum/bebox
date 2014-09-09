
module Bebox
  module ProjectCommands

    include Bebox::CommandsHelper

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      load_environment_commands
      load_node_commands
      load_role_profile_commands
      load_prepare_commands
      load_provision_commands
    end

    # Load environment commands
    def load_environment_commands
      self.extend Bebox::EnvironmentCommands
    end

    # Load node commands if there are environments configured
    def load_node_commands
      (self.extend Bebox::NodeCommands) if Bebox::Environment.list(project_root).count > 0
    end

    # Load role/profile commands
    def load_role_profile_commands
      if Bebox::Node.count_all_nodes_by_type(project_root, 'phase-0') > 0
        self.extend Bebox::RoleCommands
        self.extend Bebox::ProfileCommands
      end
    end

    # Load prepare commands if there are at least one node
    def load_prepare_commands
      (self.extend Bebox::PrepareCommands) if Bebox::Node.count_all_nodes_by_type(project_root, 'phase-0') > 0
    end

    # Load provision commands if there are nodes prepared
    def load_provision_commands
      (self.extend Bebox::ProvisionCommands) if Bebox::Node.count_all_nodes_by_type(project_root, 'phase-1') > 0
    end
  end
end