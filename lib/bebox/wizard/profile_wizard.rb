require_relative '../profile'
require 'highline/import'

module Bebox
  class ProfileWizard

    # Create a new profile
    def self.create_new_profile(project_root, profile_name)
      # Check if the profile exist
      return "The profile #{profile_name} already exist!." if profile_exists?(project_root, profile_name)
      # Profile creation
      profile = Bebox::Profile.new(profile_name, project_root)
      profile.create
      "Profile created!."
    end

    # Removes an existing profile
    def self.remove_profile(project_root, profile_name)
      # Check if the profile exist
      return "The profile #{profile_name} did not exist!." unless profile_exists?(project_root, profile_name)
      # Confirm deletion
      return "Nothing done!." unless confirm_profile_deletion?
      # Profile deletion
      profile = Bebox::Profile.new(profile_name, project_root)
      profile.remove
      "Profile removed!."
    end

    # Lists existing profiles
    def self.list_profiles(project_root)
      Profile.list(project_root)
    end

    # Check if there's an existent profile in the project
    def self.profile_exists?(project_root, profile_name)
      Dir.exists?("#{project_root}/puppet/profiles/#{profile_name}")
    end

    # Ask for confirmation of profile deletion
    def self.confirm_profile_deletion?
      say('Are you sure that you want to delete the profile?')
      response =  ask("(y/n)")do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Asks to choose an existent profile
    def self.choose_profile(profiles)
      choose do |menu|
        menu.header = 'Choose an existent profile:'
        profiles.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end
  end
end