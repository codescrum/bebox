module Bebox
  class Puppet

    attr_accessor :environment

    def initialize(environment)
      self.environment = environment
    end

    def install
      `cd #{self.environment.project_path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:install`
    end
  end
end