require 'tilt'

module Bebox
  class Profile

    attr_accessor :project_root, :name

    def initialize(name, project_root)
      self.project_root = project_root
      self.name = name
    end

    # Create all files and directories related to a profile
    def create
      create_profile_directory
      generate_manifests_file
      generate_puppetfile
    end

    # Delete all files and directories related to a profile
    def remove
      `cd #{self.project_root} && rm -r puppet/profiles/#{self.name}`
    end

    # Lists existing profiles
    def self.list(project_root)
      Dir["#{project_root}/puppet/profiles/*"].map { |f| File.basename(f) }
    end

    # Create the directories for the profile
    def create_profile_directory
      `cd #{self.project_root} && mkdir -p puppet/profiles/#{self.name}/manifests`
    end

    # Generate the manifests init.pp file
    def generate_manifests_file
      manifests_template = Tilt::ERBTemplate.new("#{templates_path}/puppet/profiles/manifests/init.pp.erb")
      File.open("#{self.path}/manifests/init.pp", 'w') do |f|
        f.write manifests_template.render(nil, :profile => self)
      end
    end

    # Generate the Puppetfile
    def generate_puppetfile
      puppetfile_template = Tilt::ERBTemplate.new("#{templates_path}/puppet/profiles/Puppetfile.erb")
      File.open("#{self.path}/Puppetfile", 'w') do |f|
        f.write puppetfile_template.render(nil)
      end
    end

    # Path to the templates directory in the gem
    def templates_path
      File.join((File.expand_path '..', File.dirname(__FILE__)), 'templates')
    end

    # Path to the role directory in the project
    def path
      "#{self.project_root}/puppet/profiles/#{self.name}"
    end

    # Counts existing profiles
    def self.profiles_count(project_root)
      Bebox::Profile.list(project_root).count
    end
  end
end