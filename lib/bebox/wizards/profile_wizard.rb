require 'bebox/profile'

module Bebox
  class ProfileWizard
    include Bebox::Logger
    include Bebox::WizardsHelper

    # Create a new profile
    def create_new_profile(project_root, profile_name, profile_base_path)
      # Check if the profile name is valid
      return error "The profile name can only contain:\n
      \n* Lowercase letters
      \n* Numbers
      \n* Underscores
      \n* Must begin with an Lowercase letter
      \n* Can not be any of: #{Bebox::RESERVED_WORDS.join(', ')}
      \n\nNo changes were made." unless Bebox::Profile.valid_name?(profile_name)
      # Clean the profile_path to make it a valid path
      profile_base_path = Bebox::Profile.cleanpath(profile_base_path)
      unless profile_base_path.empty?
        # Check if the path name is valid
        return error "Each part of the path can only contain:\n
          \n* Lowercase letters
          \n* Numbers
          \n* Underscores
          \n* Must begin with an Lowercase letter
          \n* Can not be any of: #{Bebox::RESERVED_WORDS.join(', ')}
          \n\nNo changes were made." unless Bebox::Profile.valid_pathname?(profile_base_path)
      end
      # Check if the profile exist
      profile_path = profile_complete_path(profile_base_path, profile_name)
      return error("The profile '#{profile_path}' already exist. No changes were made.") if profile_exists?(project_root, profile_path)
      # Profile creation
      profile = Bebox::Profile.new(profile_name, project_root, profile_base_path)
      profile.create
      ok "Profile '#{profile_path}' created!."
    end

    # Removes an existing profile
    def remove_profile(project_root)
      # Choose a profile from the availables
      profiles = Bebox::Profile.list(project_root)
      # Get a profile if exist
      if profiles.count > 0
        profile = choose_profile(profiles, 'Choose the profile to remove:')
      else
        return error "There are no profiles to remove. No changes were made."
      end
      # Ask for deletion confirmation
      return warn('No changes were made.') unless confirm_action?('Are you sure that you want to delete the profile?')
      # Profile deletion
      profile_name = profile.split('/').last
      profile_base_path = profile.split('/')[0...-1].join('/')
      profile = Bebox::Profile.new(profile_name, project_root, profile_base_path)
      profile.remove
      ok 'Profile removed!.'
    end

    # Lists existing profiles
    def list_profiles(project_root)
      Profile.list(project_root)
    end

    # Create the complete profile path with name
    def profile_complete_path(profile_base_path, profile_name)
      File.join("#{profile_base_path}", "#{profile_name}")
    end

    # Check if there's an existing profile in the project
    def profile_exists?(project_root, profile_path)
      Dir.exists?( File.join("#{project_root}/puppet/profiles", "#{profile_path}") )
    end

    # Asks to choose a profile
    def choose_profile(profiles, question)
      choose do |menu|
        menu.header = title(question)
        profiles.each do |box|
          menu.choice(box)
        end
      end
    end
  end
end