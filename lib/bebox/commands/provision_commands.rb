require 'bebox/profile'

module Bebox
  module ProvisionCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      desc 'Apply the Puppet step for the nodes in a environment. (step-0: Fundamental, step-1: User layer, step-2: Service layer, step-3: Security layer)'
      arg_name "[step]"
      command :apply do |apply_command|
        apply_command.switch :all, :desc => 'Apply all steps in sequence.', :negatable => false
        apply_command.flag :environment, :desc => 'Set the environment of nodes', default_value: default_environment
        apply_command.action do |global_options,options,args|
          environment = get_environment(options)
          require 'bebox/wizards/puppet_wizard'
          if options[:all]
            title "Provisioning all steps..."
            Bebox::PUPPET_STEPS.each do |step|
              title "Provisioning #{step}:"
              Bebox::PuppetWizard.new.apply_step(project_root, environment, step)
            end
          else
            step = args.first
            help_now!(error('You did not specify an step')) if args.count == 0
            help_now!(error('You did not specify a valid step')) unless valid_step?(step)
            # Apply the step for the environment
            title "Provisioning #{step}:"
            Bebox::PuppetWizard.new.apply_step(project_root, environment, step)
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
            require 'bebox/wizards/profile_wizard'
            profiles = Bebox::ProfileWizard.new.list_profiles(project_root)
            title 'Current profiles :'
            profiles.map{|profile| msg(profile)}
            warn('There are not profiles yet. You can create a new one with: \'bebox profile new\' command.') if profiles.empty?
            linebreak
          end
        end
        # Profile new command
        profile_command.desc 'add a profile in the project'
        profile_command.arg_name "[name]"
        profile_command.command :new do |profile_new_command|
          profile_new_command.flag :p, :arg_name => 'path', :desc => 'A relative path of the category folders tree to store the profile. Ex. basic/security/iptables'
          profile_new_command.action do |global_options,options,args|
            path = options[:p] || ''
            help_now!(error('You did not supply a name')) if args.count == 0
            require 'bebox/wizards/profile_wizard'
            Bebox::ProfileWizard.new.create_new_profile(project_root, args.first, path)
          end
        end
        # Profile remove command
        profile_command.desc "remove a profile in the project"
        # profile_command.arg_name "[name]"
        profile_command.command :remove do |profile_remove_command|
          profile_remove_command.action do |global_options,options,args|
            # help_now!(error('You did not supply a profile name')) if args.count == 0
            require 'bebox/wizards/profile_wizard'
            Bebox::ProfileWizard.new.remove_profile(project_root)
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
            title 'Current roles :'
            roles.map{|role| msg(role)}
            warn('There are not roles yet. You can create a new one with: \'bebox role new\' command.') if roles.empty?
            linebreak
          end
        end
        # Role new command
        role_command.desc 'add a role to the project'
        role_command.arg_name "[name]"
        role_command.command :new do |role_new_command|
          role_new_command.action do |global_options,options,args|
            help_now!(error('You did not supply a name')) if args.count == 0
            require 'bebox/wizards/role_wizard'
            Bebox::RoleWizard.new.create_new_role(project_root, args.first)
          end
        end
        # Role remove command
        role_command.desc "remove a role in the project"
        role_command.arg_name "[name]"
        role_command.command :remove do |role_remove_command|
          role_remove_command.action do |global_options,options,args|
            help_now!(error('You did not supply a role name')) if args.count == 0
            require 'bebox/wizards/role_wizard'
            Bebox::RoleWizard.new.remove_role(project_root, args.first)
          end
        end

        # These commands are available if there are at least one role and one profile
        if Bebox::Role.roles_count(project_root) > 0 && Bebox::Profile.profiles_count(project_root) > 0
          # Role list profiles command
          role_command.desc 'list the profiles in a role'
          role_command.arg_name "[role_name]"
          role_command.command :list_profiles do |list_profiles_command|
            list_profiles_command.action do |global_options,options,args|
              help_now!(error('You did not supply a role name.')) if args.count == 0
              role = args.first
              require 'bebox/wizards/role_wizard'
              exit_now!(error('The supplied role do not exist.')) unless Bebox::RoleWizard.new.role_exists?(project_root, role)
              profiles = Bebox::Role.list_profiles(project_root, role)
              title "Current profiles in role #{role}:"
              profiles.map{|profile| msg(profile)}
              warn("There are not profiles in role #{role}. You can add a new one with: 'bebox role add_profile' command.") if profiles.empty?
              linebreak
            end
          end
          # Role add profile command
          role_command.desc 'add a profile to a role'
          role_command.command :add_profile do |add_profile_command|
            add_profile_command.action do |global_options,options,args|
              require 'bebox/wizards/role_wizard'
              Bebox::RoleWizard.new.add_profile(project_root)
            end
          end
          # Role remove profile command
          role_command.desc "remove a profile in a role"
          role_command.command :remove_profile do |remove_profile_command|
            remove_profile_command.action do |global_options,options,args|
              require 'bebox/wizards/role_wizard'
              Bebox::RoleWizard.new.remove_profile(project_root)
            end
          end
        end
      end
    end
  end
end