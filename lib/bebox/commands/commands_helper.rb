require 'bebox/wizards/wizards_helper'

module Bebox
  module CommandsHelper
    include Bebox::WizardsHelper
    # Obtain the environment from command parameters or menu
    def get_environment(options)
      environment = options[:environment]
      # Ask for environment of node if flag environment not set
      environment ||= choose_option(Environment.list(project_root), 'Choose an existing environment:')
      # Check environment existence
      Bebox::Environment.environment_exists?(project_root, environment) ? (return environment) : exit_now!(error("The '#{environment}' environment does not exist."))
    end

    # Obtain the default environment for a project
    def default_environment
      environments = Bebox::Environment.list(project_root)
      if environments.count > 0
        return environments.include?('vagrant') ? 'vagrant' : environments.first
      else
        return ''
      end
    end

    # Check if vagrant is installed on the machine
    def vagrant_installed?
      (`which vagrant`) == 'vagrant not found' ? false : true
    end

    # Check if the step argument is valid
    def valid_step?(step)
      steps = %w{step-0 step-1 step-2 step-3}
      steps.include?(step)
    end
  end
end