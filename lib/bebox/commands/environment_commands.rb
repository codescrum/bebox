module Bebox
  module EnvironmentCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      # Environment management phase commands
      desc 'Manage environments for the project. The \'vagrant\', \'production\' and \'staging\' environments are present by default.'
      command :environment do |environment_command|
        # Environment list command
        environment_command.desc 'list the remote environments in the project'
        environment_command.command :list do |environment_list_command|
          environment_list_command.action do |global_options,options,args|
            require 'bebox/environment'
            environments = Bebox::Environment.list(project_root)
            title 'Current environments :'
            environments.map{|environment| msg(environment)}
            warn('There are not environments yet. You can create a new one with: \'bebox environment new\' command.') if environments.empty?
          end
        end
        # Environment new command
        environment_command.desc 'add a remote environment to the project'
        environment_command.arg_name "[environment]"
        environment_command.command :new do |environment_new_command|
          environment_new_command.action do |global_options,options,args|
            help_now!(error('You don\'t supply an environment')) if args.count == 0
            require 'bebox/wizards/environment_wizard'
            Bebox::EnvironmentWizard.new.create_new_environment(project_root, args.first)
          end
        end
        # Environment remove command
        environment_command.desc "remove a remote environment in the project"
        environment_command.arg_name "[environment]"
        environment_command.command :remove do |environment_remove_command|
          environment_remove_command.action do |global_options,options,args|
            help_now!(error('You don\'t supply an environment')) if args.count == 0
            require 'bebox/wizards/environment_wizard'
            Bebox::EnvironmentWizard.new.remove_environment(project_root, args.first)
          end
        end
      end
    end
  end
end