module Bebox
  module GeneralCommands

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
  end
end