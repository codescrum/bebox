require 'bebox/commands/commands_helper'

module Bebox
  module EnvironmentCommands
    def load_environment_commands
      # Environment management phase commands
      desc 'Manage environments for the project. The \'vagrant\', \'production\' and \'staging\' environments are present by default.'
      command :environment do |environment_command|
        # Environment list command
        environment_command.desc 'list the remote environments in the project'
        environment_command.command :list do |environment_list_command|
          environment_list_command.action do |global_options,options,args|
            environments = Bebox::EnvironmentWizard.list_environments(project_root)
            say("\nCurrent environments :\n\n")
            environments.map{|environment| say(environment)}
            say("There are not environments yet. You can create a new one with: 'bebox environment new' command.") if environments.empty?
          end
        end
        # Environment new command
        environment_command.desc 'add a remote environment to the project'
        environment_command.arg_name "[environment]"
        environment_command.command :new do |environment_new_command|
          environment_new_command.action do |global_options,options,args|
            help_now!('You don\'t supply an environment') if args.count == 0
            creation_message = Bebox::EnvironmentWizard.create_new_environment(project_root, args.first)
            puts creation_message
          end
        end
        # Environment remove command
        environment_command.desc "remove a remote environment in the project"
        environment_command.arg_name "[environment]"
        environment_command.command :remove do |environment_remove_command|
          environment_remove_command.action do |global_options,options,args|
            help_now!('You don\'t supply an environment') if args.count == 0
            deletion_message = Bebox::EnvironmentWizard.remove_environment(project_root, args.first)
            puts deletion_message
          end
        end
      end
    end
  end
end