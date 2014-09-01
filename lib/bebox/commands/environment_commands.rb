
module Bebox
  module EnvironmentCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      # Environment management phase commands
      desc 'Manage environments for the project. The \'vagrant\', \'production\' and \'staging\' environments are present by default.'
      command :environment do |environment_command|
        environment_list_command(environment_command)
        generate_environment_command(environment_command, :new, :create_new_environment, 'Add a remote environment to the project')
        generate_environment_command(environment_command, :remove, :remove_environment, 'Remove a remote environment in the project')
      end
    end

    def generate_environment_command(environment_command, command, send_command, description)
      environment_command.desc description
      environment_command.arg_name "[environment]"
      environment_command.command command do |generated_command|
        generated_command.action do |global_options,options,args|
          help_now!(error('You did not supply an environment')) if args.count == 0
          Bebox::EnvironmentWizard.new.send(send_command, project_root, args.first)
        end
      end
    end

    # Environment list command
    def environment_list_command(environment_command)
      environment_command.desc 'List the remote environments in the project'
      environment_command.command :list do |environment_list_command|
        environment_list_command.action do |global_options,options,args|
          environments = Bebox::Environment.list(project_root)
          title 'Current environments:'
          environments.map{|environment| msg(environment)}
          warn('There are not environments yet. You can create a new one with: \'bebox environment new\' command.') if environments.empty?
        end
      end
    end
  end
end