
module Bebox
  module RoleCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      desc _('cli.role.desc')
      command :role do |role_command|
        role_new_command(role_command)
        generate_role_command(role_command, :remove, :remove_role, _('cli.role.remove.desc'))
        role_list_command(role_command)
        # These commands are available if there are at least one role and one profile
        load_role_profile_commands(role_command) if (Bebox::Role.roles_count(project_root) > 0 && Bebox::Profile.profiles_count(project_root) > 0)
      end
    end

    # Role list command
    def role_list_command(role_command)
      role_command.desc _('cli.role.list.desc')
      role_command.command :list do |role_list_command|
        role_list_command.action do |global_options,options,args|
          roles = Bebox::Role.list(project_root)
          title _('cli.role.list.current_roles')
          roles.map{|role| msg(role)}
          warn(_('cli.role.list.no_roles')) if roles.empty?
          linebreak
        end
      end
    end

    # Role new command
    def role_new_command(role_command)
      role_command.desc _('cli.role.new.desc')
      role_command.arg_name "[name]"
      role_command.command :new do |role_new_command|
        role_new_command.action do |global_options,options,args|
          help_now!(error(_('cli.role.new.name_arg_missing'))) if args.count == 0
          Bebox::RoleWizard.new.create_new_role(project_root, args.first)
        end
      end
    end

    def load_role_profile_commands(role_command)
      generate_role_command(role_command, :add_profile, :add_profile, _('cli.role.add_profile.desc'))
      generate_role_command(role_command, :remove_profile, :remove_profile, _('cli.role.remove_profile.desc'))
      role_list_profiles_command(role_command)
    end

    # For add_profile remove_profile and remove_role commands
    def generate_role_command(role_command, command, send_command, description)
      role_command.desc description
      role_command.command command do |generated_command|
        generated_command.action do |global_options,options,args|
          Bebox::RoleWizard.new.send(send_command, project_root)
        end
      end
    end

    # Role list profiles command
    def role_list_profiles_command(role_command)
      role_command.desc _('cli.role.list_profiles.desc')
      role_command.arg_name "[role_name]"
      role_command.command :list_profiles do |list_profiles_command|
        list_profiles_command.action do |global_options,options,args|
          help_now!(error(_('cli.role.list_profiles.name_arg_missing'))) if args.count == 0
          role = args.first
          print_profiles(role, Bebox::Role.list_profiles(project_root, role))
        end
      end
    end

    def print_profiles(role, profiles)
      exit_now!(error(_('cli.role.list_profiles.name_not_exist')%{role: role})) unless Bebox::RoleWizard.new.role_exists?(project_root, role)
      title _('cli.role.list_profiles.current_profiles')%{role: role}
      profiles.map{|profile| msg(profile)}
      warn(_('cli.role.list_profiles.no_profiles')%{role: role}) if profiles.empty?
      linebreak
    end
  end
end