require 'bebox/role'

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
      \n\nNo changes were made." unless Bebox::Role.valid_name?(role_name)
      # Check if the role exist
      return error("The '#{role_name}' role already exist. No changes were made.") if role_exists?(project_root, role_name)
      # Role creation
      role = Bebox::Role.new(role_name, project_root)
      role.create
      ok 'Role created!.'
    end

    # Removes an existing role
    def remove_role(project_root)
      # Choose a role from the availables
      roles = Bebox::Role.list(project_root)
      # Get a role if exist.
      if roles.count > 0
        role_name = choose_role(roles, 'Choose the role to remove:')
      else
        return error "There are no roles to remove. No changes were made."
      end
      # Ask for deletion confirmation
      return warn('No changes were made.') unless confirm_action?('Are you sure that you want to delete the role?')
      # Role deletion
      role = Bebox::Role.new(role_name, project_root)
      role.remove
      ok 'Role removed!.'
    end

    # Add a profile to a role
    def add_profile(project_root)
      roles = Bebox::Role.list(project_root)
      profiles = Bebox::Profile.list(project_root)
      role = choose_role(roles, 'Choose an existing role:')
      require 'bebox/wizards/profile_wizard'
      profile = Bebox::ProfileWizard.new.choose_profile(profiles, 'Choose the profile to add:')
      if Bebox::Role.profile_in_role?(project_root, role, profile)
        return warn("Profile '#{profile}' already in the Role '#{role}'. No changes were made.")
      else
        Bebox::Role.add_profile(project_root, role, profile)
        return ok("Profile '#{profile}' added to Role '#{role}'.")
      end
    end

    # Remove a profile in a role
    def remove_profile(project_root)
      roles = Bebox::Role.list(project_root)
      profiles = Bebox::Profile.list(project_root)
      role = choose_role(roles, 'Choose an existing role:')
      require 'bebox/wizards/profile_wizard'
      profile = Bebox::ProfileWizard.new.choose_profile(profiles, 'Choose the profile to remove:')
      if Bebox::Role.profile_in_role?(project_root, role, profile)
        Bebox::Role.remove_profile(project_root, role, profile)
        return ok("Profile '#{profile}' removed from Role '#{role}'.")
      else
        return warn("Profile '#{profile}' is not in the Role '#{role}'. No changes were made.")
      end

    end

    # Asks to choose an existing role
    def choose_role(roles, question)
      choose do |menu|
        menu.header = title(question)
        roles.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end

    # Check if there's an existing role in the project
    def role_exists?(project_root, role_name)
      Dir.exists?("#{project_root}/puppet/roles/#{role_name}")
    end
  end
end