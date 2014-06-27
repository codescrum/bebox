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
      `cd #{self.project_root} && mkdir -p puppet/roles/#{self.name}/manifests`
      `cd #{self.project_root} && touch puppet/roles/#{self.name}/manifests/init.pp`
    end

    # Delete all files and directories related to a role
    def remove
      `cd #{self.project_root} && rm -r puppet/roles/#{self.name}`
    end

    # Lists existing roles
    def self.list(project_root)
      Dir["#{project_root}/puppet/roles/*"].map { |f| File.basename(f) }
    end

  end
end