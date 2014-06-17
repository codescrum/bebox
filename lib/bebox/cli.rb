require 'gli'
require 'highline/import'

module Bebox
  class Cli

    attr_accessor :project_root

    def initialize(*args)
      # add the GLI magic on to the Bebox::Cli instance
      self.extend GLI::App

      program_desc 'Create basic provisioning of remote servers.'
      version Bebox::VERSION

      load_bebox_commands

      exit run(*args)
    end

    # load the commands, wheater general or project-specific
    def load_bebox_commands
      inside_project? ? load_project_commands : load_general_commands
    end

    # do the recursive stuff directory searchivn .gboobex
    def inside_project?
      project_found = false
      cwd = Pathname(Dir.pwd)
      home_directory = File.expand_path('~')
      cwd.ascend do |current_path|
        project_found = File.file?("#{current_path.to_s}/.bebox")
        self.project_root = current_path.to_s if project_found
        break if project_found || (current_path.to_s == home_directory)
      end
      project_found
    end

    # load general commands
    def load_general_commands
      # Project creation phase command
      desc 'Create a new bebox project through a simple wizard'
      arg_name '[project_name]'
      command :new do |project_command|
        project_command.action do |global_options,options,args|
          if args.count > 0
            creation_message = Bebox::ProjectWizard.create_new_project(args.first)
            puts creation_message
          else
            help_now!('You don\'t supply a project name')
          end
        end
      end
    end

  # load project commands
    def load_project_commands
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
            Bebox::EnvironmentWizard.create_new_environment(project_root, args.first)
          end
        end
        # Environment remove command
        environment_command.desc "remove a remote environment in the project"
        environment_command.arg_name "[environment]"
        environment_command.command :remove do |environment_remove_command|
          environment_remove_command.action do |global_options,options,args|
            help_now!('You don\'t supply an environment') if args.count == 0
            Bebox::EnvironmentWizard.remove_environment(project_root, args.first)
          end
        end
        # # Phase 2: Installation of bundle gems and capistrano in project
        # project.install_dependencies
        # # Phase 3: Creation and run of Vagrant nodes for project
        # environment = project.environment_by_name('vagrant')
        # environment.up
        # # Phase 4: Installation of minimal development packages in Vagrant nodes
        # environment.install_common_dev
        # # Phase 5: Installation of puppet in Vagrant nodes
        # common_modules = Bebox::Wizard.setup_modules
        # puppet = Bebox::Puppet.new(environment, common_modules)
        # puppet.install
        # # Phase 6: Creation and access setup for users (puppet, application_user) in Vagrant nodes
        # puppet.apply_users
        # # Phase 7: Setup common modules for puppet in Vagrant nodes
        # puppet.setup_modules
        # # Phase 8: Install common modules for puppet in Vagrant nodes
        # puppet.apply_common_modules
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