require 'bebox/profile'

module Bebox
  class ProfileWizard
    include Bebox::Logger
    # Create a new profile
    def create_new_profile(project_root, profile_name, profile_base_path)
      # Check if the profile name is valid
      return error "The profile name can only contain:\n
      \n* Lowercase letters
      \n* Numbers
      \n* Underscores
      \n* Must begin with an Lowercase letter
      \n* Can not be any of: #{Bebox::RESERVED_WORDS.join(', ')}
      \n\nNothing done!." unless Bebox::Profile.valid_name?(profile_name)
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
          \n\nNothing done!." unless Bebox::Profile.valid_pathname?(profile_base_path)
      end
      # Check if the profile exist
      profile_path = profile_complete_path(profile_base_path, profile_name)
      return error("The profile #{profile_path} already exist!.") if profile_exists?(project_root, profile_path)
      # Profile creation
      profile = Bebox::Profile.new(profile_name, project_root, profile_base_path)
      profile.create
      ok "Profile #{profile_path} created!."
    end

    # Removes an existing profile
    def remove_profile(project_root, profile_name)
      # Check if the profile exist
      return error("The profile #{profile_name} did not exist!.") unless profile_exists?(project_root, profile_name)
      # Confirm deletion
      return warn('Nothing done!.') unless confirm_profile_deletion?
      # Profile deletion
      profile = Bebox::Profile.new(profile_name, project_root)
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

    # Check if there's an existent profile in the project
    def profile_exists?(project_root, profile_path)
      Dir.exists?( File.join("#{project_root}/puppet/profiles", "#{profile_path}") )
    end

    # Ask for confirmation of profile deletion
    def confirm_profile_deletion?
      quest 'Are you sure that you want to delete the profile?'
      response =  ask(highline_quest('(y/n)')) do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
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