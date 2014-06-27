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
      `cd #{self.project_root} && mkdir -p puppet/profiles/#{self.name}/manifests`
      `cd #{self.project_root} && touch puppet/profiles/#{self.name}/manifests/init.pp`
      `cd #{self.project_root} && touch puppet/profiles/#{self.name}/Puppetfile`
    end

    # Delete all files and directories related to a profile
    def remove
      `cd #{self.project_root} && rm -r puppet/profiles/#{self.name}`
    end

    # Lists existing profiles
    def self.list(project_root)
      Dir["#{project_root}/puppet/profiles/*"].map { |f| File.basename(f) }
    end
  end
end