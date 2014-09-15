
module Bebox
  class Cli
    include Bebox::Logger

    attr_accessor :project_root

    def initialize(*args)

      # Configure the i18n directory and locale
      FastGettext.add_text_domain('bebox', path: Pathname(__FILE__).dirname.parent + 'i18n', type: :yaml)
      FastGettext.locale = 'en'
      FastGettext.text_domain = 'bebox'

      # add the GLI magic on to the Bebox::Cli instance
      self.extend GLI::App

      program_desc _('cli.desc')
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
      home_path = Pathname('~').expand_path
      Pathname.pwd.ascend do |directory|
        self.project_root = directory.to_s and return true if (directory + '.bebox').file?
        return false if directory == home_path
      end
    end
  end
end