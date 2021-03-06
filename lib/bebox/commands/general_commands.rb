module Bebox
  module GeneralCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      # Project creation phase command
      desc _('cli.project.new.desc')
      arg_name '[project_name]'
      command :new do |project_command|
        project_command.action do |global_options,options,args|
          if args.count > 0
            Bebox::ProjectWizard.new.create_new_project("bebox-#{args.first}")
          else
            help_now!(error(_('cli.project.new.name_arg_missing')))
          end
        end
      end
    end
  end
end