require 'tilt'
require 'bebox/puppet_module'

module Bebox
  class Puppet

    attr_accessor :environment, :common_modules

    def initialize(environment, common_modules)
      self.environment = environment
      self.common_modules = parse_common_modules(common_modules)
    end

    # Installation of puppet the machine (phase 5)
    def install
      `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:install -s phase='puppet_install'`
    end

    # Creation and access setup for users (puppet, application_user) in machine (Phase 6)
    def apply_users
    	`cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:apply_users -s phase='apply_users'`
    end

    # Prepare the puppet user for deploy
    def prepare_puppet_user
      `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} deploy:prepare_puppet_user -s phase='deploy_puppet_user'`
    end

    # Setup and apply security puppet modules in the machine (Phase 9)
    def install_security
      # setup_security_modules
      apply_security_modules
    end

    # Setup common modules (manifest, hiera, puppetfile, librarian_puppet) for puppet in the machine (Phase 7)
    def setup_modules
      setup_manifest
      setup_common_hiera
      generate_puppetfile
      prepare_puppet_user
      bundle_modules
    end

    # Setup security modules (manifest, hiera, puppetfile, librarian_puppet) for security in the machine
    def setup_security_modules
      setup_security_manifest
      setup_security_common_hiera
      generate_security_puppetfile
      prepare_puppet_user
      bundle_modules
    end

    # Puppet apply the common modules for puppet in the machine (Phase 8)
    def apply_common_modules
      `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:apply -s phase='apply_modules'`
    end

    # Puppet apply the security modules for puppet in the machine
    def apply_security_modules
      `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:apply -s phase='apply_security_modules'`
    end

    # Download the modules in the puppet user machine through librarian puppet
    def bundle_modules
      `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:bundle_modules -s phase='bundle_modules'`
    end

    # Generate the Puppetfile from the template
    def generate_puppetfile
      puppetfile_template = Tilt::ERBTemplate.new("templates/Puppetfile.erb", :trim => true)
      File.open("#{self.environment.project.path}/puppet/Puppetfile", 'w') do |f|
        f.write puppetfile_template.render(self.common_modules)
      end
    end

    # Generate the site.pp from the template
    def setup_manifest
      manifest_template = Tilt::ERBTemplate.new("templates/puppet/manifests/site.pp.erb", :trim => true)
      File.open("#{self.environment.project.path}/puppet/manifests/site.pp", 'w') do |f|
        f.write manifest_template.render(self.common_modules)
      end
    end

    # Generate the hiera data from the template
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

        # Generate the security Puppetfile from the template
    def generate_security_puppetfile
      puppetfile_template = Tilt::ERBTemplate.new("templates/Puppetfile_security.erb", :trim => true)
      File.open("#{self.environment.project.path}/puppet/Puppetfile", 'w') do |f|
        f.write puppetfile_template.render(self.common_modules)
      end
    end

    # Generate the security site.pp from the template
    def setup_security_manifest
      manifest_template = Tilt::ERBTemplate.new("templates/puppet/manifests/site_security.pp.erb", :trim => true)
      File.open("#{self.environment.project.path}/puppet/manifests/site.pp", 'w') do |f|
        f.write manifest_template.render(self.common_modules)
      end
    end

    # Generate the security hiera data from the template
    def setup_security_common_hiera
      common_hiera_template = Tilt::ERBTemplate.new("templates/puppet/hiera/data/common_security.yaml.erb")
      File.open("#{self.environment.project.path}/puppet/hiera/data/common.yaml", 'w') do |f|
        f.write common_hiera_template.render(self)
      end
    end

    # Generate the PuppetModule objects array from the user module names choices array
    def parse_common_modules(common_modules)
      common_modules_array = []
      yaml_modules = YAML.load(File.read('config/modules.yaml'))
      yaml_modules['common_modules'].each do |puppet_module, options|
        options = {} if options.nil?
        common_modules_array << Bebox::PuppetModule.new(options) if common_modules.include?(puppet_module)
      end
      common_modules_array
    end
  end
end