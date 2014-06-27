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
  end
end