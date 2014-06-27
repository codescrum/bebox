require_relative '../role'
require 'highline/import'

module Bebox
  class RoleWizard

    # Create a new role
    def self.create_new_role(project_root, role_name)
      # Check if the role exist
      return "The role #{role_name} already exist!." if role_exists?(project_root, role_name)
      # Role creation
      role = Bebox::Role.new(role_name, project_root)
      role.create
      "Role created!."
    end

    # Removes an existing role
    def self.remove_role(project_root, role_name)
      # Check if the role exist
      return "The role #{role_name} did not exist!." unless role_exists?(project_root, role_name)
      # Confirm deletion
      return "Nothing done!." unless confirm_role_deletion?
      # Role deletion
      role = Bebox::Role.new(role_name, project_root)
      role.remove
      "Role removed!."
    end

    # Add a profile to a role
    def self.add_profile(project_root)
      roles = Bebox::Role.list(project_root)
      profiles = Bebox::Profile.list(project_root)
      role = choose_role(roles)
      profile = choose_profile(profiles)
      if Bebox::Role.profile_in_role?(project_root, role, profile)
        return "Profile #{profile} already in the Role #{role}"
      else
        Bebox::Role.add_profile(project_root, role, profile)
        return "Profile #{profile} added to Role #{role}."
      end
    end

    # Remove a profile in a role
    def self.remove_profile(project_root)
      roles = Bebox::Role.list(project_root)
      profiles = Bebox::Profile.list(project_root)
      role = choose_role(roles)
      profile = choose_profile(profiles)
      if Bebox::Role.profile_in_role?(project_root, role, profile)
        Bebox::Role.remove_profile(project_root, role, profile)
        return "Profile #{profile} removed from Role #{role}."
      else
        return "Profile #{profile} is not in the Role #{role}"
      end

    end

    # Asks to choose an existent role
    def self.choose_role(roles)
      choose do |menu|
        menu.header = 'Choose an existent role:'
        roles.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end

    # Asks to choose an existent profile
    def self.choose_profile(profiles)
      choose do |menu|
        menu.header = 'Choose the profile to add:'
        profiles.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end

    # Check if there's an existent role in the project
    def self.role_exists?(project_root, role_name)
      Dir.exists?("#{project_root}/puppet/roles/#{role_name}")
    end

    # Ask for confirmation of role deletion
    def self.confirm_role_deletion?
      say('Are you sure that you want to delete the role?')
      response =  ask("(y/n)")do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Asks to choose an existent role
    def self.choose_role(roles)
      choose do |menu|
        menu.header = 'Choose an existent role:'
        roles.each do |box|
          menu.choice(box.split('/').last)
        end
      end
    end
  end
end