require_relative 'environment'
require 'highline/import'

module Bebox
  class EnvironmentWizard

    # Create a new environment
    def self.create_new_environment(environment_name)

    end

    # Removes an existing environment
    def self.remove_environment(environment_name)

    end

    # Lists existing environments
    def self.list_environments(project_root)
      Environment.list(project_root)
    end

    # Check if there's an existent environment in the project
    def self.environment_exists?(parent_path, project_name)
      Dir.exists?("#{parent_path}/#{project_name}")
    end

    # Validate environment name
    def self.valid_environment?
    end

    # Ask for confirmation of environment deletion
    def self.confirm_environment_deletion?

    end
  end
end