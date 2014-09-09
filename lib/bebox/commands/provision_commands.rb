
module Bebox
  module ProvisionCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      load_provision_commands
    end

    def load_provision_commands
      desc 'Apply the Puppet step for the nodes in a environment. (step-0: Fundamental, step-1: User layer, step-2: Service layer, step-3: Security layer)'
      arg_name "[step]"
      command :apply do |apply_command|
        apply_command.switch :all, :desc => 'Apply all steps in sequence.', :negatable => false
        apply_command.flag :environment, :desc => 'Set the environment of nodes', default_value: default_environment
        apply_command.action do |global_options,options,args|
          environment = get_environment(options)
          title "Environment: #{environment}"
          options[:all] ? apply_all(environment) : apply(environment, args)
        end
      end
    end

    def apply_all(environment)
      title "Provisioning all steps..."
      Bebox::PROVISION_STEPS.each do |step|
        Bebox::ProvisionWizard.new.apply_step(project_root, environment, step)
      end
    end

    def apply(environment, args)
      step = args.first
      help_now!(error('You did not specify an step')) if args.count == 0
      help_now!(error('You did not specify a valid step')) unless valid_step?(step)
      Bebox::ProvisionWizard.new.apply_step(project_root, environment, step)
    end
  end
end