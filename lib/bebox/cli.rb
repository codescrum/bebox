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

    # Obtain the environment from command parameters or menu
    def get_environment(options)
      environment = options[:environment]
      # Ask for environment of node if flag environment not set
      environment ||= Bebox::NodeWizard.choose_environment(Environment.list(project_root))
      # Check environment existence
      Bebox::EnvironmentWizard.environment_exists?(project_root, environment) ? (return environment) : exit_now!('The specified environment don\'t exist.')
    end

    # Obtain the default environment for a project
    def default_environment
      environments = Bebox::EnvironmentWizard.list_environments(project_root)
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

      # This commands only run if there are environments configured
      if Bebox::EnvironmentWizard.list_environments(project_root).count > 0
        # Nodes management phase commands
        desc 'Manage nodes for a environment in the project.'
        command :node do |node_command|
          # Node list command
          node_command.flag :environment, :desc => 'Set the environment of nodes', default_value: default_environment
          node_command.desc 'list the nodes in a environment'
          node_command.command :list do |node_list_command|
            node_list_command.switch :all
            node_list_command.action do |global_options,options,args|
              # Call to list nodes
              if options[:all].present?
                Bebox::NodeWizard.list_all_nodes(project_root)
              else
                environment = get_environment(options)
                say("\nEnvironment #{environment}.\n\n")
                nodes = Bebox::NodeWizard.list_nodes(project_root, environment, 'nodes')
                say("Nodes :\n\n")
                nodes.map{|node| say(node)}
                say("There are not nodes yet. You can create a new one with: 'bebox node new' command.") if nodes.empty?
                say("\n")
              end
            end
          end
          # Node new command
          node_command.desc 'add a node to a environment'
          node_command.command :new do |node_new_command|
            node_new_command.action do |global_options,options,args|
              environment = get_environment(options)
              say("\nEnvironment #{environment}.\n\n")
              creation_message = Bebox::NodeWizard.create_new_node(project_root, environment)
              puts creation_message
            end
          end
          # Node remove command
          node_command.desc "remove a node in a environment"
          node_command.command :remove do |node_remove_command|
            node_remove_command.action do |global_options,options,args|
              environment = get_environment(options)
              say("\nEnvironment #{environment}.\n\n")
              deletion_message = Bebox::NodeWizard.remove_node(project_root, environment, args.first)
              puts deletion_message
            end
          end
          # These commands are available if there is at least one role
          if Bebox::Role.roles_count(project_root) > 0
            # Associate node to role command
            node_command.desc "Associate a node with a role in a environment"
            node_command.command :set_role do |node_role_command|
              node_role_command.action do |global_options,options,args|
                environment = get_environment(options)
                say("\nEnvironment #{environment}.\n\n")
                creation_message = Bebox::NodeWizard.set_role(project_root, environment)
                puts creation_message
              end
            end
          end
        end

        # These commands are available if there are at least one node configured in the project
        if Bebox::NodeWizard.nodes_count(project_root) > 0
          # Prepare nodes phase commands
          desc 'Prepare the nodes for the environment.'
          command :prepare do |prepare_command|
            prepare_command.flag :environment, :desc => 'Set the environment of node', default_value: default_environment
            prepare_command.action do |global_options,options,args|
              environment = get_environment(options)
              # Check if vagrant is installed
              return 'Vagrant is not installed in the system. Nothing done.' unless vagrant_installed?
              say("\nEnvironment #{environment}.\n")
              Bebox::NodeWizard.prepare(project_root, environment)
            end
          end
          # These commands are available if there are at least one node in the vagrant environment
          if Bebox::NodeWizard.list_nodes(project_root, 'vagrant', 'nodes').count > 0
            desc 'Halt the nodes for vagrant environment.'
            command :vagrant_halt do |vagrant_halt_command|
              vagrant_halt_command.action do |global_options,options,args|
                # Check if vagrant is installed
                return 'Vagrant is not installed in the system. Nothing done.' unless vagrant_installed?
                # List nodes in environment and notice message
                nodes = Bebox::Node.nodes_in_environment(project_root, 'vagrant', 'nodes')
                environment = 'vagrant'
                say("\nEnvironment #{environment}.\n")
                say("\nHalting nodes: \n")
                nodes.each{|node| say(node.hostname)}
                say("\n")
                # Halt vagrant nodes
                Bebox::NodeWizard.vagrant_halt(project_root)
              end
            end
            desc 'Up the nodes for vagrant environment.'
            command :vagrant_up do |vagrant_up_command|
              vagrant_up_command.action do |global_options,options,args|
                # Check if vagrant is installed
                return 'Vagrant is not installed in the system. Nothing done.' unless vagrant_installed?
                # List nodes in environment and notice message
                nodes = Bebox::Node.nodes_in_environment(project_root, 'vagrant', 'nodes')
                environment = 'vagrant'
                say("\nEnvironment #{environment}.\n")
                say("\nRunning up nodes: \n")
                nodes.each{|node| say(node.hostname)}
                say("\n")
                # Up vagrant nodes
                Bebox::NodeWizard.vagrant_up(project_root)
              end
            end
          end

          # These commands are available if there are at least one prepared_node
          if Bebox::PuppetWizard.prepared_nodes_count(project_root) > 0
            desc 'Apply the Puppet step for the nodes in a environment. (step-0: Fundamental, step-1: User layer, step-2: Service layer, step-3: Security layer)'
            arg_name "[step]"
            command :apply do |apply_command|
              apply_command.flag :environment, :desc => 'Set the environment of nodes', default_value: default_environment
              apply_command.action do |global_options,options,args|
                environment = get_environment(options)
                step = args.first
                help_now!('You did not specify an step') if args.count == 0
                help_now!('You did not specify a valid step') unless valid_step?(step)
                # Apply the step for the environment
                Bebox::PuppetWizard.apply_step(project_root, environment, step)
              end
            end
            # Roles commands
            desc 'Manage roles for the node provisioning phase.'
            command :role do |role_command|
              # Role list command
              role_command.desc 'list the roles in the project'
              role_command.command :list do |role_list_command|
                role_list_command.action do |global_options,options,args|
                  roles = Bebox::Role.list(project_root)
                  say("\nCurrent roles :\n\n")
                  roles.map{|role| say(role)}
                  say("There are not roles yet. You can create a new one with: 'bebox role new' command.") if roles.empty?
                  say("\n")
                end
              end
              # Role new command
              role_command.desc 'add a role to the project'
              role_command.arg_name "[name]"
              role_command.command :new do |role_new_command|
                role_new_command.action do |global_options,options,args|
                  help_now!('You did not supply a name') if args.count == 0
                  creation_message = Bebox::RoleWizard.create_new_role(project_root, args.first)
                  puts creation_message
                end
              end
              # Role remove command
              role_command.desc "remove a role in the project"
              role_command.arg_name "[name]"
              role_command.command :remove do |role_remove_command|
                role_remove_command.action do |global_options,options,args|
                  help_now!('You did not supply a role name') if args.count == 0
                  deletion_message = Bebox::RoleWizard.remove_role(project_root, args.first)
                  puts deletion_message
                end
              end

              # These commands are available if there are at least one role and one profile
              if Bebox::Role.roles_count(project_root) > 0 && Bebox::Profile.profiles_count(project_root) > 0
                # Role list profiles command
                role_command.desc 'list the profiles in a role'
                role_command.arg_name "[role_name]"
                role_command.command :list_profiles do |list_profiles_command|
                  list_profiles_command.action do |global_options,options,args|
                    help_now!('You did not supply a role name.') if args.count == 0
                    role = args.first
                    exit_now!('The supplied role do not exist.') unless Bebox::RoleWizard.role_exists?(project_root, role)
                    profiles = Bebox::Role.list_profiles(project_root, role)
                    say("\nCurrent profiles in role #{role}:\n\n")
                    profiles.map{|profile| say(profile)}
                    say("There are not profiles in role #{role}. You can add a new one with: 'bebox role add_profile' command.") if profiles.empty?
                    say("\n")
                  end
                end
                # Role add profile command
                role_command.desc 'add a profile to a role'
                role_command.command :add_profile do |add_profile_command|
                  add_profile_command.action do |global_options,options,args|
                    creation_message = Bebox::RoleWizard.add_profile(project_root)
                    puts creation_message
                  end
                end
                # Role remove profile command
                role_command.desc "remove a profile in a role"
                role_command.command :remove_profile do |remove_profile_command|
                  remove_profile_command.action do |global_options,options,args|
                    deletion_message = Bebox::RoleWizard.remove_profile(project_root)
                    puts deletion_message
                  end
                end
              end
            end
            # Profile commands
            desc 'Manage profiles for the node provisioning phase.'
            command :profile do |profile_command|
              # Profile list command
              profile_command.desc 'list the profiles in the project'
              profile_command.command :list do |profile_list_command|
                profile_list_command.action do |global_options,options,args|
                  profiles = Bebox::ProfileWizard.list_profiles(project_root)
                  say("\nCurrent profiles :\n\n")
                  profiles.map{|profile| say(profile)}
                  say("There are not profiles yet. You can create a new one with: 'bebox profile new' command.") if profiles.empty?
                  say("\n")
                end
              end
              # Profile new command
              profile_command.desc 'add a profile in the project'
              profile_command.arg_name "[name]"
              profile_command.command :new do |profile_new_command|
                profile_new_command.action do |global_options,options,args|
                  help_now!('You did not supply a name') if args.count == 0
                  creation_message = Bebox::ProfileWizard.create_new_profile(project_root, args.first)
                  puts creation_message
                end
              end
              # Profile remove command
              profile_command.desc "remove a profile in the project"
              profile_command.arg_name "[name]"
              profile_command.command :remove do |profile_remove_command|
                profile_remove_command.action do |global_options,options,args|
                  help_now!('You did not supply a profile name') if args.count == 0
                  deletion_message = Bebox::ProfileWizard.remove_profile(project_root, args.first)
                  puts deletion_message
                end
              end
            end
          end
        end
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