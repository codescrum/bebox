
module Bebox
  class RoleWizard
    include Bebox::Logger
    include Bebox::WizardsHelper

    # Create a new role
    def create_new_role(project_root, role_name)
      # Check if the role name is valid
      return error _('wizard.role.invalid_name')%{words: Bebox::RESERVED_WORDS.join(', ')} unless valid_puppet_class_name?(role_name)
      # Check if the role exist
      return error(_('wizard.role.name_exist')%{role: role_name}) if role_exists?(project_root, role_name)
      # Role creation
      role = Bebox::Role.new(role_name, project_root)
      output = role.create
      ok _('wizard.role.creation_success')
      return output
    end

    # Removes an existing role
    def remove_role(project_root)
      # Choose a role from the availables
      roles = Bebox::Role.list(project_root)
      # Get a role if exist.
      if roles.count > 0
        role_name = choose_option(roles, _('wizard.role.choose_deletion_role'))
      else
        return error _('wizard.role.no_deletion_roles')
      end
      # Ask for deletion confirmation
      return warn(_('wizard.no_changes')) unless confirm_action?(_('wizard.role.confirm_deletion'))
      # Role deletion
      role = Bebox::Role.new(role_name, project_root)
      output = role.remove
      ok _('wizard.role.deletion_success')
      return output
    end

    # Add a profile to a role
    def add_profile(project_root)
      roles = Bebox::Role.list(project_root)
      profiles = Bebox::Profile.list(project_root)
      role = choose_option(roles, _('wizard.choose_role'))
      profile = choose_option(profiles, _('wizard.role.choose_add_profile'))
      if Bebox::Role.profile_in_role?(project_root, role, profile)
        warn _('wizard.role.profile_exist')%{profile: profile, role: role}
        output = false
      else
        output = Bebox::Role.add_profile(project_root, role, profile)
        ok _('wizard.role.add_profile_success')%{profile: profile, role: role}
      end
      return output
    end

    # Remove a profile in a role
    def remove_profile(project_root)
      roles = Bebox::Role.list(project_root)
      profiles = Bebox::Profile.list(project_root)
      role = choose_option(roles, _('wizard.choose_role'))
      profile = choose_option(profiles, _('wizard.choose_remove_profile'))
      if Bebox::Role.profile_in_role?(project_root, role, profile)
        output = Bebox::Role.remove_profile(project_root, role, profile)
        ok _('wizard.role.remove_profile_success')%{profile: profile, role: role}
      else
        warn _('wizard.role.profile_not_exist')%{profile: profile, role: role}
        output = false
      end
      return output
    end

    # Check if there's an existing role in the project
    def role_exists?(project_root, role_name)
      Dir.exists?("#{project_root}/puppet/roles/#{role_name}")
    end
  end
end