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

    def configure_common_modules
      copy_modules
      setup_manifest
      setup_common_hiera
      deploy
      apply_common_modules
    end

    def copy_modules
      `cp -r lib/modules/* #{self.environment.project.path}/puppet/modules`
    end

    def setup_manifest
      manifest_template = Tilt::ERBTemplate.new("templates/puppet/manifests/site.pp.erb")
      File.open("#{self.environment.project.path}/puppet/manifests/site.pp", 'w') do |f|
        f.write manifest_template.render(self)
      end
    end

    def setup_common_hiera
      hiera_template = Tilt::ERBTemplate.new("templates/puppet/hiera/hiera.yaml.erb")
      File.open("#{self.environment.project.path}/puppet/hiera/hiera.yaml", 'w') do |f|
        f.write hiera_template.render(self)
      end
      common_hiera_template = Tilt::ERBTemplate.new("templates/puppet/hiera/data/common.yaml.erb")
      File.open("#{self.environment.project.path}/puppet/hiera/data/common.yaml", 'w') do |f|
        f.write common_hiera_template.render(self)
      end
    end

    def apply_common_modules
      `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:apply -s phase='apply_modules'`
    end

  end
end