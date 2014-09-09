
module Bebox
  module PrepareCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      load_prepare_command
      # These commands are available if there are at least one node in the vagrant environment
      (Bebox::Node.list(project_root, 'vagrant', 'phase-1').count > 0) ? load_vagrant_commands : return
    end

    def load_prepare_command
      desc _('cli.prepare.desc')
      command :prepare do |prepare_command|
        prepare_command.flag :environment, :desc => _('cli.prepare.env_flag_desc'), default_value: default_environment
        prepare_command.action do |global_options,options,args|
          environment = get_environment(options)
          # Check if vagrant is installed
          return error(_('cli.prepare.not_vagrant')) unless Bebox::CommandsHelper.vagrant_installed?
          title _('cli.current_environment')%{environment: environment}
          Bebox::NodeWizard.new.prepare(project_root, environment)
        end
      end
    end

    def load_vagrant_commands
      desc _('cli.prepare.vagrant_halt.desc')
      command :vagrant_halt do |vagrant_halt_command|
        vagrant_halt_command.action do |global_options,options,args|
          vagrant_command(:halt_vagrant_nodes, _('cli.prepare.vagrant_halt.halt_title'))
        end
      end
      desc _('cli.prepare.vagrant_up.desc')
      command :vagrant_up do |vagrant_up_command|
        vagrant_up_command.action do |global_options,options,args|
          vagrant_command(:up_vagrant_nodes, _('cli.prepare.vagrant_up.up_title'))
        end
      end
    end

    def vagrant_command(command, message)
      # Check if vagrant is installed
      return error(_('cli.prepare.not_vagrant')) unless Bebox::CommandsHelper.vagrant_installed?
      nodes = Bebox::Node.nodes_in_environment(project_root, 'vagrant', 'phase-0')
      title _('cli.current_environment')%{environment: 'vagrant'}
      title message
      nodes.each{|node| msg(node.hostname)}
      linebreak
      Bebox::VagrantHelper.send(command, project_root)
    end
  end
end