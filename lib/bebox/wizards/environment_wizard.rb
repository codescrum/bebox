module Bebox
  class EnvironmentWizard
    include Bebox::Logger
    include Bebox::WizardsHelper

    # Create a new environment
    def create_new_environment(project_root, environment_name)
      # Check if the environment exist
      return error("The '#{environment_name}' environment already exist!.") if Bebox::Environment.environment_exists?(project_root, environment_name)
      # Environment creation
      environment = Bebox::Environment.new(environment_name, project_root)
      environment.create
      ok 'Environment created!.'
    end

    # Removes an existing environment
    def remove_environment(project_root, environment_name)
      # Check if the environment exist
      return error("The '#{environment_name}' environment do not exist!.") unless Bebox::Environment.environment_exists?(project_root, environment_name)
      # Confirm deletion
      return warn('No changes were made.') unless confirm_action?('Are you sure that you want to delete the environment?')
      # Environment deletion
      environment = Bebox::Environment.new(environment_name, project_root)
      environment.remove
      ok 'Environment removed!.'
    end
  end
end