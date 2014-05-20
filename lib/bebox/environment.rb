module Bebox
  class Environment

    UBUNTU_DEPENDENCIES = %w(git-core build-essential curl)
    attr_accessor :name, :project

    def initialize(name, project)
      self.name = name
      self.project = project
    end

    def prepare_boxes
      system "cd #{self.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap deploy:prepare"
    end

  end
end