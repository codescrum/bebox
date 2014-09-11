
module Bebox
  module ProfileCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      desc _('cli.profile.desc')
      command :profile do |profile_command|
        profile_new_command(profile_command)
        profile_remove_command(profile_command)
        profile_list_command(profile_command)
      end
    end

    # Profile new command
    def profile_new_command(profile_command)
      profile_command.desc _('cli.profile.new.desc')
      profile_command.arg_name "[name]"
      profile_command.command :new do |profile_new_command|
        profile_new_command.flag :p, :arg_name => 'path', :desc => _('cli.profile.new.path_flag_desc')
        profile_new_command.action do |global_options,options,args|
          path = options[:p] || ''
          help_now!(error(_('cli.profile.new.name_arg_missing'))) if args.count == 0
          Bebox::ProfileWizard.new.create_new_profile(project_root, args.first, path)
        end
      end
    end

    # Profile remove command
    def profile_remove_command(profile_command)
      profile_command.desc _('cli.profile.remove.desc')
      profile_command.command :remove do |profile_remove_command|
        profile_remove_command.action do |global_options,options,args|
          Bebox::ProfileWizard.new.remove_profile(project_root)
        end
      end
    end

    # Profile list command
    def profile_list_command(profile_command)
      profile_command.desc _('cli.profile.list.desc')
      profile_command.command :list do |profile_list_command|
        profile_list_command.action do |global_options,options,args|
          profiles = Bebox::ProfileWizard.new.list_profiles(project_root)
          title _('cli.profile.list.current_profiles')
          profiles.map{|profile| msg(profile)}
          warn(_('cli.profile.list.no_profiles')) if profiles.empty?
          linebreak
        end
      end
    end
  end
end