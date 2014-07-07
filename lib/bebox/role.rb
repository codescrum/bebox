require 'tilt'

module Bebox
  class Role

    attr_accessor :project_root, :name

    def initialize(name, project_root)
      self.project_root = project_root
      self.name = name
    end

    # Create all files and directories related to a role
    def create
      create_role_directory
      generate_manifests_file
    end

    # Delete all files and directories related to a role
    def remove
      `cd #{self.project_root} && rm -r puppet/roles/#{self.name}`
    end

    # Lists existing roles
    def self.list(project_root)
      Dir["#{project_root}/puppet/roles/*"].map { |f| File.basename(f) }
    end

    # Create the directories for the role
    def create_role_directory
    `cd #{self.project_root} && mkdir -p puppet/roles/#{self.name}/manifests`
    end

    # Generate the manifests init.pp file
    def generate_manifests_file
      manifests_template = Tilt::ERBTemplate.new("#{templates_path}/puppet/roles/manifests/init.pp.erb")
      File.open("#{self.path}/manifests/init.pp", 'w') do |f|
        f.write manifests_template.render(nil, :role => self)
      end
    end

    # Path to the templates directory in the gem
    def templates_path
      File.join((File.expand_path '..', File.dirname(__FILE__)), 'templates')
    end

    # Path to the role directory in the project
    def path
      "#{self.project_root}/puppet/roles/#{self.name}"
    end

    # Counts existing roles
    def self.roles_count(project_root)
      Bebox::Role.list(project_root).count
    end

    # Add a profile to a role
    def self.add_profile(project_root, role, profile)
      tempfile_path = "#{project_root}/puppet/roles/#{role}/manifests/init.pp.tmp"
      manifest_path = "#{project_root}/puppet/roles/#{role}/manifests/init.pp"
      tempfile = File.open(tempfile_path, 'w')
      manifest_file = File.new(manifest_path)
      manifest_file.each do |line|
        line << "\n\tinclude profiles::#{profile}\n" if line.start_with?('class')
        tempfile << line
      end
      manifest_file.close
      tempfile.close
      FileUtils.mv(tempfile_path, manifest_path)
    end

    # Remove a profile in a role
    def self.remove_profile(project_root, role, profile)
      manifest_path = "#{project_root}/puppet/roles/#{role}/manifests/init.pp"
      regexp = /^\s*include\s+profiles::#{profile}\s*$/
      content = File.read(manifest_path).gsub(regexp, '')
      File.open(manifest_path, 'wb') { |file| file.write(content) }
    end

    # List profiles in a role
    def self.list_profiles(project_root, role)
      profiles = []
      File.readlines("#{project_root}/puppet/roles/#{role}/manifests/init.pp").each do |line|
        row = line.strip
        next if row.start_with?('#')
        profiles << row.split('::').last if row.start_with?('include')
      end
      profiles
    end

    # Check if a profile is defined in a role
    def self.profile_in_role?(project_root, role, profile)
      role_profiles = Bebox::Role.list_profiles(project_root, role)
      role_profiles.include?(profile) ? true : false
    end
  end
end