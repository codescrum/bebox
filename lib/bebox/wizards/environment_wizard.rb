
module Bebox
  class EnvironmentWizard
    include Bebox::Logger
    include Bebox::WizardsHelper

    # Create a new environment
    def create_new_environment(project_root, environment_name)
      # Check if the environment exist
      return error(_('wizard.environment.name_exist')%{environment: environment_name}) if Bebox::Environment.environment_exists?(project_root, environment_name)
      # Environment creation
      environment = Bebox::Environment.new(environment_name, project_root)
      output = environment.create
      ok _('wizard.environment.creation_success')
      return output
    end

    # Removes an existing environment
    def remove_environment(project_root, environment_name)
      # Check if the environment exist
      return error(_('wizard.environment.name_not_exist')%{environment: environment_name}) unless Bebox::Environment.environment_exists?(project_root, environment_name)
      # Confirm deletion
      return warn(_('wizard.no_changes')) unless confirm_action?(_('wizard.environment.confirm_deletion'))
      # Environment deletion
      environment = Bebox::Environment.new(environment_name, project_root)
      output = environment.remove
      ok _('wizard.environment.deletion_success')
      return output
    end
  end
end