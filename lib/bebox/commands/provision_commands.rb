
module Bebox
  module ProvisionCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      load_provision_commands
    end

    def load_provision_commands
      desc _('cli.provision.desc')
      arg_name "[step]"
      command :apply do |apply_command|
        apply_command.switch :all, :desc => _('cli.provision.all_switch_desc'), :negatable => false
        apply_command.flag :environment, :desc => _('cli.provision.env_flag_desc'), default_value: default_environment
        apply_command.action do |global_options,options,args|
          environment = get_environment(options)
          title _('cli.current_environment')%{environment: environment}
          options[:all] ? apply_all(environment) : apply(environment, args)
        end
      end
    end

    def apply_all(environment)
      title _('cli.provision.title')
      Bebox::PROVISION_STEPS.each do |step|
        Bebox::ProvisionWizard.new.apply_step(project_root, environment, step)
      end
    end

    def apply(environment, args)
      step = args.first
      help_now!(error(_('cli.provision.name_missing'))) if args.count == 0
      help_now!(error(_('cli.provision.name_invalid'))) unless Bebox::CommandsHelper.valid_step?(step)
      Bebox::ProvisionWizard.new.apply_step(project_root, environment, step)
    end
  end
end