
module Bebox
  module ProfileCommands

    def self.extended(base)
      base.load_commands
    end

    def load_commands
      desc 'Manage profiles for the node provisioning phase.'
      command :profile do |profile_command|
        profile_new_command(profile_command)
        profile_remove_command(profile_command)
        profile_list_command(profile_command)
      end
    end

    # Profile new command
    def profile_new_command(profile_command)
      profile_command.desc 'Add a profile to the project'
      profile_command.arg_name "[name]"
      profile_command.command :new do |profile_new_command|
        profile_new_command.flag :p, :arg_name => 'path', :desc => 'A relative path of the category folders tree to store the profile. Ex. basic/security/iptables'
        profile_new_command.action do |global_options,options,args|
          path = options[:p] || ''
          help_now!(error('You did not supply a name')) if args.count == 0
          Bebox::ProfileWizard.new.create_new_profile(project_root, args.first, path)
        end
      end
    end

    # Profile remove command
    def profile_remove_command(profile_command)
      profile_command.desc "Remove a profile from the project"
      profile_command.command :remove do |profile_remove_command|
        profile_remove_command.action do |global_options,options,args|
          Bebox::ProfileWizard.new.remove_profile(project_root)
        end
      end
    end

    # Profile list command
    def profile_list_command(profile_command)
      profile_command.desc 'List the profiles in the project'
      profile_command.command :list do |profile_list_command|
        profile_list_command.action do |global_options,options,args|
          profiles = Bebox::ProfileWizard.new.list_profiles(project_root)
          title 'Current profiles:'
          profiles.map{|profile| msg(profile)}
          warn('There are not profiles yet. You can create a new one with: \'bebox profile new\' command.') if profiles.empty?
          linebreak
        end
      end
    end
  end
end