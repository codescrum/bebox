
module Bebox
  module EnvironmentCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      # Environment management phase commands
      desc _('cli.environment.desc')
      command :environment do |environment_command|
        environment_list_command(environment_command)
        generate_environment_command(environment_command, :new, :create_new_environment, _('cli.environment.new.desc'))
        generate_environment_command(environment_command, :remove, :remove_environment, _('cli.environment.remove.desc'))
      end
    end

    def generate_environment_command(environment_command, command, send_command, description)
      environment_command.desc description
      environment_command.arg_name "[environment]"
      environment_command.command command do |generated_command|
        generated_command.action do |global_options,options,args|
          help_now!(error(_('cli.environment.name_arg_missing'))) if args.count == 0
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
          title _('cli.environment.list.current_envs')
          environments.map{|environment| msg(environment)}
          warn(_('cli.environment.list.no_envs')) if environments.empty?
        end
      end
    end
  end
end