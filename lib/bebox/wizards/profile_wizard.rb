
module Bebox
  class ProfileWizard
    include Bebox::Logger
    include Bebox::WizardsHelper

    # Create a new profile
    def create_new_profile(project_root, profile_name, profile_base_path)
      # Clean the profile_path to make it a valid path
      profile_base_path = Bebox::Profile.cleanpath(profile_base_path)
      # Check if the profile name is valid
      return unless name_valid?(profile_name, profile_base_path)
      # Check if the profile exist
      profile_path = profile_base_path.empty? ? profile_name : profile_complete_path(profile_base_path, profile_name)
      return error(_('wizard.profile.name_exist')%{profile: profile_path}) if profile_exists?(project_root, profile_path)
      # Profile creation
      profile = Bebox::Profile.new(profile_name, project_root, profile_base_path)
      output = profile.create
      ok _('wizard.profile.creation_success')%{profile: profile_path}
      return output
    end

    # Check if the profile name is valid
    def name_valid?(profile_name, profile_base_path)
      unless valid_puppet_class_name?(profile_name)
        error _('wizard.profile.invalid_name')%{words: Bebox::RESERVED_WORDS.join(', ')}
        return false
      end
      return true if profile_base_path.empty?
      # Check if the path name is valid
      unless Bebox::Profile.valid_pathname?(profile_base_path)
        error _('wizard.profile.invalid_path')%{words: Bebox::RESERVED_WORDS.join(', ')}
        return false
      end
      true
    end

    # Removes an existing profile
    def remove_profile(project_root)
      # Choose a profile from the availables
      profiles = Bebox::Profile.list(project_root)
      # Get a profile if exist
      if profiles.count > 0
        profile = choose_option(profiles, _('wizard.choose_remove_profile'))
      else
        return error _('wizard.profile.no_deletion_profiles')
      end
      # Ask for deletion confirmation
      return warn(_('wizard.no_changes')) unless confirm_action?(_('wizard.profile.confirm_deletion'))
      # Profile deletion
      profile_name = profile.split('/').last
      profile_base_path = profile.split('/')[0...-1].join('/')
      profile = Bebox::Profile.new(profile_name, project_root, profile_base_path)
      output = profile.remove
      ok _('wizard.profile.deletion_success')
      return output
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
  end
end