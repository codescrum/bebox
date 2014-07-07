require 'gli'
require 'highline/import'
require 'colorize'
require 'bebox/commands/general_commands'
require 'bebox/commands/project_commands'

module Bebox
  class Cli
    include Bebox::GeneralCommands
    include Bebox::ProjectCommands

    attr_accessor :project_root

    def initialize(*args)
      # add the GLI magic on to the Bebox::Cli instance
      self.extend GLI::App

      program_desc 'Create basic provisioning of remote servers.'
      version Bebox::VERSION

      inside_project? ? load_project_commands : load_general_commands
      exit run(*args)
    end

    # do the recursive stuff directory searchivn .gboobex
    def inside_project?
      project_found = false
      cwd = Pathname(Dir.pwd)
      home_directory = File.expand_path('~')
      cwd.ascend do |current_path|
        project_found = File.file?("#{current_path.to_s}/.bebox")
        self.project_root = current_path.to_s if project_found
        break if project_found || (current_path.to_s == home_directory)
      end
      project_found
    end
  end
end