require_relative 'environment'
require 'highline/import'

module Bebox
  class EnvironmentWizard

    # Create a new environment
    def self.create_new_environment(project_root, environment_name)
      # Check if the environment exist
      return "The environment #{environment_name} already exist!." if environment_exists?(project_root, environment_name)
      # Environment creation
      environment = Bebox::Environment.new(environment_name, project_root)
      environment.create
      "Environment created!."
    end

    # Removes an existing environment
    def self.remove_environment(project_root, environment_name)
      # Check if the environment exist
      return "The environment #{environment_name} don't exist!." unless environment_exists?(project_root, environment_name)
      # Confirm deletion
      return "Nothing done!." unless confirm_environment_deletion?
      # Environment deletion
      environment = Bebox::Environment.new(environment_name, project_root)
      environment.remove
      "Environment removed!."
    end

    # Lists existing environments
    def self.list_environments(project_root)
      Environment.list(project_root)
    end

    # Check if there's an existent environment in the project
    def self.environment_exists?(project_root, environment_name)
      Dir.exists?("#{project_root}/.checkpoints/environments/#{environment_name}")
    end

    # Ask for confirmation of environment deletion
    def self.confirm_environment_deletion?
      say('Are you sure that you want to delete the environment?')
      response =  ask("(y/n)")do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Asks to choose an existent environment
    def self.choose_environment(environments)
      choose do |menu|
        menu.header = 'Choose an existent environment:'
        environments.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end
  end
end