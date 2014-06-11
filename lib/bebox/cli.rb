require 'gli'
require 'highline/import'

module Bebox
  class Cli

    def initialize(*args)

      # add the GLI magic on to the Bebox::Cli instance
      self.extend GLI::App

      program_desc 'Create basic provisioning of remote servers.'
      version Bebox::VERSION

      load_bebox_commands
      # load_hooks
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
        project_found = File.exists?("#{current_path.to_s}/.bebox")
        break if project_found || (current_path.to_s == home_directory)
      end
      project_found
    end



    def load_general_commands

      desc 'Create a new bebox project through a simple wizard'
      arg_name 'The project name, "bebox new my_project"'
      command :new do |c|
        c.action do |global_options,options,args|
          # Project creation phase
          project = Bebox::Wizard.create_new_project(args.first)
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
      end
    end

    def load_project_commands

      desc 'Create the new vagrant machine(s) to my project through a simple wizard'
      arg_name 'The project name, "bebox environment new <environment>"'
      command :environment do |c|
        c.action do |global_options,options,args|

        end
      end

      pre do |global_options,command,options,args|
        # Pre logic here
        # Return true to proceed; false to abort and not call the
        # chosen command
        # Use skips_pre before a command to skip this block
        # on that command only
        true
      end

      post do |global_options,command,options,args|
        # Post logic here
        # Use skips_post before a command to skip this
        # block on that command only
      end

      on_error do |exception|
        # Error logic here
        # return false to skip default error handling
        true
      end

    end
  end
end