
module Bebox
  class Cli
    include Bebox::Logger

    attr_accessor :project_root

    def initialize(*args)
      # add the GLI magic on to the Bebox::Cli instance
      self.extend GLI::App

      program_desc 'Create basic provisioning of remote servers.'
      version Bebox::VERSION

      if inside_project?
        self.extend Bebox::ProjectCommands
      else
        self.extend Bebox::GeneralCommands
      end
      exit run(*args)
    end

    # Search recursively for .bebox file to see
    # if current directory is a bebox project or not
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