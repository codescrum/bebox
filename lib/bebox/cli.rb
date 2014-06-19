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
                nodes = Bebox::NodeWizard.list_nodes(project_root, environment)
                say("Nodes :\n\n")
                nodes.map{|node| say(node)}
                say("There are not nodes yet. You can create a new one with: 'bebox node new' command.") if nodes.empty?
                say("\n")
              end
            end
          end
          # Node new command
          node_command.desc 'add a node to a environment'
          #node_command.arg_name "[node]"
          node_command.command :new do |node_new_command|
            node_new_command.action do |global_options,options,args|
              #help_now!('You don\'t supply a node') if args.count == 0
              environment = get_environment(options)
              say("\nEnvironment #{environment}.\n\n")
              creation_message = Bebox::NodeWizard.create_new_node(project_root, environment)
              puts creation_message
            end
          end
          # Node remove command
          node_command.desc "remove a node in a environment"
          # node_command.arg_name "[node_hostname]"
          node_command.command :remove do |node_remove_command|
            node_remove_command.action do |global_options,options,args|
              # help_now!('You don\'t supply a node') if args.count == 0
              environment = get_environment(options)
              say("\nEnvironment #{environment}.\n\n")
              deletion_message = Bebox::NodeWizard.remove_node(project_root, environment, args.first)
              puts deletion_message
            end
          end
        end

        if Bebox::NodeWizard.list_nodes(project_root, 'vagrant').count > 0
          # Prepare nodes phase commands
          desc 'Prepare the nodes for vagrant environment.'
          command :prepare do |prepare_command|
            prepare_command.flag :environment, :desc => 'Set the environment of node', default_value: default_environment
            prepare_command.action do |global_options,options,args|
              return 'Vagrant is not installed in the system. Nothing done.' unless vagrant_installed?
              nodes = Bebox::Node.node_objects(project_root, 'vagrant')
              environment = get_environment(options)
              say("\nEnvironment #{environment}.\n")
              say("\nPreparing nodes: \n")
              nodes.each{|node| say(node.hostname)}
              say("\n")
              Bebox::NodeWizard.prepare(project_root, environment)
            end
          end
          desc 'Halt the nodes for vagrant environment.'
          command :vagrant_halt do |vagrant_halt_command|
            vagrant_halt_command.action do |global_options,options,args|
              return 'Vagrant is not installed in the system. Nothing done.' unless vagrant_installed?
              nodes = Bebox::Node.node_objects(project_root, 'vagrant')
              environment = 'vagrant'
              say("\nEnvironment #{environment}.\n")
              say("\nHalting nodes: \n")
              nodes.each{|node| say(node.hostname)}
              say("\n")
              Bebox::NodeWizard.vagrant_halt(project_root)
            end
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