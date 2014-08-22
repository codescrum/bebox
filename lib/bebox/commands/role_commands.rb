require 'bebox/profile'
require 'bebox/wizards/role_wizard'


module Bebox
  module RoleCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      desc 'Manage roles for the node provisioning phase.'
      command :role do |role_command|
        role_new_command(role_command)
        generate_role_command(role_command, :remove, :remove_role, 'Remove a role from the project')
        role_list_command(role_command)
        # These commands are available if there are at least one role and one profile
        (Bebox::Role.roles_count(project_root) > 0 && Bebox::Profile.profiles_count(project_root) > 0) ? load_role_profile_commands(role_command) : return
      end
    end

    # Role list command
    def role_list_command(role_command)
      role_command.desc 'List the roles in the project'
      role_command.command :list do |role_list_command|
        role_list_command.action do |global_options,options,args|
          roles = Bebox::Role.list(project_root)
          title 'Current roles:'
          roles.map{|role| msg(role)}
          warn('There are not roles yet. You can create a new one with: \'bebox role new\' command.') if roles.empty?
          linebreak
        end
      end
    end

    # Role new command
    def role_new_command(role_command)
      role_command.desc 'Add a role to the project'
      role_command.arg_name "[name]"
      role_command.command :new do |role_new_command|
        role_new_command.action do |global_options,options,args|
          help_now!(error('You did not supply a name')) if args.count == 0
          Bebox::RoleWizard.new.create_new_role(project_root, args.first)
        end
      end
    end

    def load_role_profile_commands(role_command)
      generate_role_command(role_command, :add_profile, :add_profile, 'Add a profile to a role')
      generate_role_command(role_command, :remove_profile, :remove_profile, 'Remove a profile from a role')
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
      role_command.desc 'List the profiles in a role'
      role_command.arg_name "[role_name]"
      role_command.command :list_profiles do |list_profiles_command|
        list_profiles_command.action do |global_options,options,args|
          help_now!(error('You did not supply a role name.')) if args.count == 0
          role = args.first
          exit_now!(error("The '#{role}' role does not exist.")) unless Bebox::RoleWizard.new.role_exists?(project_root, role)
          print_profiles(role, Bebox::Role.list_profiles(project_root, role))
        end
      end
    end

    def print_profiles(role, profiles)
      title "Current profiles in '#{role}' role:"
      profiles.map{|profile| msg(profile)}
      warn("There are not profiles in role '#{role}'. You can add a new one with: 'bebox role add_profile' command.") if profiles.empty?
      linebreak
    end
  end
end