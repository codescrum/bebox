
module Bebox
  class RoleWizard
    include Bebox::Logger
    include Bebox::WizardsHelper

    # Create a new role
    def create_new_role(project_root, role_name)
      # Check if the role name is valid
      return error "The role name can only contain:\n
      \n* Lowercase letters
      \n* Numbers
      \n* Underscores
      \n* Must begin with an Lowercase letter
      \n* Can not be any of: #{Bebox::RESERVED_WORDS.join(', ')}
      \n\nNo changes were made." unless valid_puppet_class_name?(role_name)
      # Check if the role exist
      return error("The '#{role_name}' role already exist. No changes were made.") if role_exists?(project_root, role_name)
      # Role creation
      role = Bebox::Role.new(role_name, project_root)
      output = role.create
      ok 'Role created!.'
      return output
    end

    # Removes an existing role
    def remove_role(project_root)
      # Choose a role from the availables
      roles = Bebox::Role.list(project_root)
      # Get a role if exist.
      if roles.count > 0
        role_name = choose_option(roles, 'Choose the role to remove:')
      else
        return error "There are no roles to remove. No changes were made."
      end
      # Ask for deletion confirmation
      return warn('No changes were made.') unless confirm_action?('Are you sure that you want to delete the role?')
      # Role deletion
      role = Bebox::Role.new(role_name, project_root)
      output = role.remove
      ok 'Role removed!.'
      return output
    end

    # Add a profile to a role
    def add_profile(project_root)
      roles = Bebox::Role.list(project_root)
      profiles = Bebox::Profile.list(project_root)
      role = choose_option(roles, 'Choose an existing role:')
      profile = choose_option(profiles, 'Choose the profile to add:')
      if Bebox::Role.profile_in_role?(project_root, role, profile)
        warn "Profile '#{profile}' already in the Role '#{role}'. No changes were made."
        output = false
      else
        output = Bebox::Role.add_profile(project_root, role, profile)
        ok "Profile '#{profile}' added to Role '#{role}'."
      end
      return output
    end

    # Remove a profile in a role
    def remove_profile(project_root)
      roles = Bebox::Role.list(project_root)
      profiles = Bebox::Profile.list(project_root)
      role = choose_option(roles, 'Choose an existing role:')
      profile = choose_option(profiles, 'Choose the profile to remove:')
      if Bebox::Role.profile_in_role?(project_root, role, profile)
        output = Bebox::Role.remove_profile(project_root, role, profile)
        ok "Profile '#{profile}' removed from Role '#{role}'."
      else
        warn "Profile '#{profile}' is not in the Role '#{role}'. No changes were made."
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