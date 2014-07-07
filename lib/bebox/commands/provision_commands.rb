require 'bebox/commands/commands_helper'

module Bebox
  module ProvisionCommands
    def load_provision_commands
      desc 'Apply the Puppet step for the nodes in a environment. (step-0: Fundamental, step-1: User layer, step-2: Service layer, step-3: Security layer)'
      arg_name "[step]"
      command :apply do |apply_command|
        apply_command.switch :all, :desc => 'Apply all steps in sequence.', :negatable => false
        apply_command.flag :environment, :desc => 'Set the environment of nodes', default_value: default_environment
        apply_command.action do |global_options,options,args|
          environment = get_environment(options)
          if options[:all]
            puts "\nProvisioning all steps...\n\n"
            Bebox::PUPPET_STEPS.each do |step|
              puts "\nProvisioning step #{step}:\n\n"
              Bebox::PuppetWizard.apply_step(project_root, environment, step)
            end
          else
            step = args.first
            help_now!('You did not specify an step') if args.count == 0
            help_now!('You did not specify a valid step') unless valid_step?(step)
            # Apply the step for the environment
            puts "\nProvisioning step #{step}:\n\n"
            Bebox::PuppetWizard.apply_step(project_root, environment, step)
          end
        end
      end

      # Profile commands
      desc 'Manage profiles for the node provisioning phase.'
      command :profile do |profile_command|
        # Profile list command
        profile_command.desc 'list the profiles in the project'
        profile_command.command :list do |profile_list_command|
          profile_list_command.action do |global_options,options,args|
            profiles = Bebox::ProfileWizard.list_profiles(project_root)
            say("\nCurrent profiles :\n\n")
            profiles.map{|profile| say(profile)}
            say("There are not profiles yet. You can create a new one with: 'bebox profile new' command.") if profiles.empty?
            say("\n")
          end
        end
        # Profile new command
        profile_command.desc 'add a profile in the project'
        profile_command.arg_name "[name]"
        profile_command.command :new do |profile_new_command|
          profile_new_command.action do |global_options,options,args|
            help_now!('You did not supply a name') if args.count == 0
            creation_message = Bebox::ProfileWizard.create_new_profile(project_root, args.first)
            puts creation_message
          end
        end
        # Profile remove command
        profile_command.desc "remove a profile in the project"
        profile_command.arg_name "[name]"
        profile_command.command :remove do |profile_remove_command|
          profile_remove_command.action do |global_options,options,args|
            help_now!('You did not supply a profile name') if args.count == 0
            deletion_message = Bebox::ProfileWizard.remove_profile(project_root, args.first)
            puts deletion_message
          end
        end
      end

      # Roles commands
      desc 'Manage roles for the node provisioning phase.'
      command :role do |role_command|
        # Role list command
        role_command.desc 'list the roles in the project'
        role_command.command :list do |role_list_command|
          role_list_command.action do |global_options,options,args|
            roles = Bebox::Role.list(project_root)
            say("\nCurrent roles :\n\n")
            roles.map{|role| say(role)}
            say("There are not roles yet. You can create a new one with: 'bebox role new' command.") if roles.empty?
            say("\n")
          end
        end
        # Role new command
        role_command.desc 'add a role to the project'
        role_command.arg_name "[name]"
        role_command.command :new do |role_new_command|
          role_new_command.action do |global_options,options,args|
            help_now!('You did not supply a name') if args.count == 0
            creation_message = Bebox::RoleWizard.create_new_role(project_root, args.first)
            puts creation_message
          end
        end
        # Role remove command
        role_command.desc "remove a role in the project"
        role_command.arg_name "[name]"
        role_command.command :remove do |role_remove_command|
          role_remove_command.action do |global_options,options,args|
            help_now!('You did not supply a role name') if args.count == 0
            deletion_message = Bebox::RoleWizard.remove_role(project_root, args.first)
            puts deletion_message
          end
        end

        # These commands are available if there are at least one role and one profile
        if Bebox::Role.roles_count(project_root) > 0 && Bebox::Profile.profiles_count(project_root) > 0
          # Role list profiles command
          role_command.desc 'list the profiles in a role'
          role_command.arg_name "[role_name]"
          role_command.command :list_profiles do |list_profiles_command|
            list_profiles_command.action do |global_options,options,args|
              help_now!('You did not supply a role name.') if args.count == 0
              role = args.first
              exit_now!('The supplied role do not exist.') unless Bebox::RoleWizard.role_exists?(project_root, role)
              profiles = Bebox::Role.list_profiles(project_root, role)
              say("\nCurrent profiles in role #{role}:\n\n")
              profiles.map{|profile| say(profile)}
              say("There are not profiles in role #{role}. You can add a new one with: 'bebox role add_profile' command.") if profiles.empty?
              say("\n")
            end
          end
          # Role add profile command
          role_command.desc 'add a profile to a role'
          role_command.command :add_profile do |add_profile_command|
            add_profile_command.action do |global_options,options,args|
              creation_message = Bebox::RoleWizard.add_profile(project_root)
              puts creation_message
            end
          end
          # Role remove profile command
          role_command.desc "remove a profile in a role"
          role_command.command :remove_profile do |remove_profile_command|
            remove_profile_command.action do |global_options,options,args|
              deletion_message = Bebox::RoleWizard.remove_profile(project_root)
              puts deletion_message
            end
          end
        end
      end
    end
  end
end