require_relative '../role'
require 'highline/import'
require 'bebox/logger'

module Bebox
  class RoleWizard
    include Bebox::Logger
    # Create a new role
    def create_new_role(project_root, role_name)
      # Check if the role exist
      return error("The role #{role_name} already exist!.") if role_exists?(project_root, role_name)
      # Role creation
      role = Bebox::Role.new(role_name, project_root)
      role.create
      ok 'Role created!.'
    end

    # Removes an existing role
    def remove_role(project_root, role_name)
      # Check if the role exist
      return error("The role #{role_name} did not exist!.") unless role_exists?(project_root, role_name)
      # Confirm deletion
      return warn('Nothing done!.') unless confirm_role_deletion?
      # Role deletion
      role = Bebox::Role.new(role_name, project_root)
      role.remove
      ok 'Role removed!.'
    end

    # Add a profile to a role
    def add_profile(project_root)
      roles = Bebox::Role.list(project_root)
      profiles = Bebox::Profile.list(project_root)
      role = choose_role(roles)
      profile = Bebox::ProfileWizard.new.choose_profile(profiles, 'Choose the profile to add:')
      if Bebox::Role.profile_in_role?(project_root, role, profile)
        return warn("Profile #{profile} already in the Role #{role}. Nothing done!.")
      else
        Bebox::Role.add_profile(project_root, role, profile)
        return ok("Profile #{profile} added to Role #{role}.")
      end
    end

    # Remove a profile in a role
    def remove_profile(project_root)
      roles = Bebox::Role.list(project_root)
      profiles = Bebox::Profile.list(project_root)
      role = choose_role(roles)
      profile = Bebox::ProfileWizard.new.choose_profile(profiles, 'Choose the profile to remove:')
      if Bebox::Role.profile_in_role?(project_root, role, profile)
        Bebox::Role.remove_profile(project_root, role, profile)
        return ok("Profile #{profile} removed from Role #{role}.")
      else
        return warn("Profile #{profile} is not in the Role #{role}. Nothing done!.")
      end

    end

    # Asks to choose an existent role
    def choose_role(roles)
      choose do |menu|
        menu.header = title('Choose an existent role:')
        roles.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end

    # Check if there's an existent role in the project
    def role_exists?(project_root, role_name)
      Dir.exists?("#{project_root}/puppet/roles/#{role_name}")
    end

    # Ask for confirmation of role deletion
    def confirm_role_deletion?
      quest 'Are you sure that you want to delete the role?'
      response =  ask(highline_quest('(y/n)')) do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end
  end
end