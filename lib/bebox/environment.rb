module Bebox
  class Environment

    UBUNTU_DEPENDENCIES = %w(git-core build-essential curl)
    attr_accessor :name, :project

    def initialize(name, project)
      self.name = name
      self.project = project
    end

  end
end