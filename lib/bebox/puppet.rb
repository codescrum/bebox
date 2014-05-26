require 'tilt'

module Bebox
  class Puppet

    attr_accessor :environment

    def initialize(environment)
      self.environment = environment
    end

    def install
      `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:install -s phase='puppet_install'`
    end

    def apply_users
    	`cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:apply_users -s phase='apply_users'`
    end

    def deploy
      `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} deploy:prepare_puppet_user -s phase='deploy_puppet_user'`
    end
  end
end