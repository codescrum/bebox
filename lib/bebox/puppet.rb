require 'tilt'
# require 'bebox/puppet_module'
require 'pry'
module Bebox
  class Puppet

    attr_accessor :environment, :project_root, :node, :step#, :common_modules

    def initialize(project_root, environment, node, step)#, common_modules)
      self.environment = environment
      self.project_root = project_root
      self.node = node
      self.step = step
      # self.common_modules = parse_common_modules(common_modules)
    end

    # Puppet apply Fundamental step
    def apply
      copy_step_0_modules if self.step == 'step-0'
      generate_hiera
      generate_puppetfile
      apply_step
      create_step_checkpoint
    end

    def copy_step_0_modules
      `cp -r #{Bebox::Puppet::templates_path}/puppet/#{self.step}/modules/* #{self.project_root}/puppet/steps/#{Bebox::Puppet.step_name(self.step)}/modules/`
    end

    # Generate the hiera data for step from the template
    def generate_hiera
      ssh_key = Bebox::Project.public_ssh_key_from_file(self.project_root, self.environment)
      hiera_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{self.step}/hiera/hiera.yaml.erb")
      File.open("#{self.project_root}/puppet/steps/#{Bebox::Puppet.step_name(self.step)}/hiera/hiera.yaml", 'w') do |f|
        f.write hiera_template.render(nil, :step_dir => Bebox::Puppet.step_name(self.step))
      end
      common_hiera_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{self.step}/hiera/data/common.yaml.erb")
      File.open("#{self.project_root}/puppet/steps/#{Bebox::Puppet.step_name(self.step)}/hiera/data/common.yaml", 'w') do |f|
        f.write common_hiera_template.render(nil, :ssh_key => ssh_key)
      end
    end

    # Generate the site.pp for step
    def self.generate_manifests(project_root, step, nodes)
      manifest_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{step}/manifests/site.pp.erb", :trim => true)
      File.open("#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp", 'w') do |f|
        f.write manifest_template.render(nil, :nodes => nodes)
      end
    end

    # Generate the Puppetfile from the template
    def generate_puppetfile
      puppetfile_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{self.step}/Puppetfile.erb", :trim => true)
      File.open("#{self.project_root}/puppet/steps/#{Bebox::Puppet.step_name(self.step)}/Puppetfile", 'w') do |f|
        f.write puppetfile_template.render(nil)
      end
    end

    # Apply step via capistrano
    def apply_step
      `cd #{self.project_root} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment} deploy:setup -S phase='#{self.step}' HOSTS=#{self.node.hostname}`
      `cd #{self.project_root} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment} deploy -S phase='#{self.step}' HOSTS=#{self.node.hostname}`
      `cd #{self.project_root} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment} puppet:apply -S phase='#{self.step}' -S step_dir='#{Bebox::Puppet.step_name(self.step)}' HOSTS=#{self.node.hostname}`
    end

    # Create checkpoint for step
    def create_step_checkpoint
      checkpoint_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/node/node.yml.erb")
      File.open("#{self.project_root}/.checkpoints/environments/#{self.environment}/steps/#{self.step}/#{self.node.hostname}.yml", 'w') do |f|
        f.write checkpoint_template.render(nil, :node => self.node)
      end
    end

    # Get the templates path inside the gem
    def self.templates_path
      File.join((File.expand_path '..', File.dirname(__FILE__)), 'templates')
    end

    def self.step_name(step)
      case step
        when 'step-0'
          '0-fundamental'
        when 'step-1'
          '1-users'
        when 'step-2'
          '2-services'
        when 'step-3'
          '3-security'
      end
    end

    # # Installation of puppet the machine (phase 5)
    # def install
    #   `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:install -s phase='puppet_install'`
    # end

    # # Creation and access setup for users (puppet, application_user) in machine (Phase 6)
    # def apply_users
    # 	`cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:apply_users -s phase='apply_users'`
    # end

    # # Prepare the puppet user for deploy
    # def prepare_puppet_user
    #   `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} deploy:prepare_puppet_user -s phase='deploy_puppet_user'`
    # end

    # # Setup and apply security puppet modules in the machine (Phase 9)
    # def install_security
    #   # setup_security_modules
    #   apply_security_modules
    # end

    # # Setup common modules (manifest, hiera, puppetfile, librarian_puppet) for puppet in the machine (Phase 7)
    # def setup_modules
    #   setup_manifest
    #   setup_common_hiera
    #   generate_puppetfile
    #   prepare_puppet_user
    #   bundle_modules
    # end

    # # Setup security modules (manifest, hiera, puppetfile, librarian_puppet) for security in the machine
    # def setup_security_modules
    #   setup_security_manifest
    #   setup_security_common_hiera
    #   generate_security_puppetfile
    #   prepare_puppet_user
    #   bundle_modules
    # end

    # # Puppet apply the common modules for puppet in the machine (Phase 8)
    # def apply_common_modules
    #   `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:apply -s phase='apply_modules'`
    # end

    # # Puppet apply the security modules for puppet in the machine
    # def apply_security_modules
    #   `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:apply -s phase='apply_security_modules'`
    # end

    # # Download the modules in the puppet user machine through librarian puppet
    # def bundle_modules
    #   `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:bundle_modules -s phase='bundle_modules'`
    # end

    # # Generate the Puppetfile from the template
    # def generate_puppetfile
    #   puppetfile_template = Tilt::ERBTemplate.new("templates/Puppetfile.erb", :trim => true)
    #   File.open("#{self.environment.project.path}/puppet/Puppetfile", 'w') do |f|
    #     f.write puppetfile_template.render(self.common_modules)
    #   end
    # end

    # # Generate the site.pp from the template
    # def setup_manifest
    #   manifest_template = Tilt::ERBTemplate.new("templates/puppet/manifests/site.pp.erb", :trim => true)
    #   File.open("#{self.environment.project.path}/puppet/manifests/site.pp", 'w') do |f|
    #     f.write manifest_template.render(self.common_modules)
    #   end
    # end

    # # Generate the hiera data from the template
    # def setup_common_hiera
    #   hiera_template = Tilt::ERBTemplate.new("templates/puppet/hiera/hiera.yaml.erb")
    #   File.open("#{self.environment.project.path}/puppet/hiera/hiera.yaml", 'w') do |f|
    #     f.write hiera_template.render(self)
    #   end
    #   common_hiera_template = Tilt::ERBTemplate.new("templates/puppet/hiera/data/common.yaml.erb")
    #   File.open("#{self.environment.project.path}/puppet/hiera/data/common.yaml", 'w') do |f|
    #     f.write common_hiera_template.render(self)
    #   end
    # end

    #     # Generate the security Puppetfile from the template
    # def generate_security_puppetfile
    #   puppetfile_template = Tilt::ERBTemplate.new("templates/Puppetfile_security.erb", :trim => true)
    #   File.open("#{self.environment.project.path}/puppet/Puppetfile", 'w') do |f|
    #     f.write puppetfile_template.render(self.common_modules)
    #   end
    # end

    # # Generate the security site.pp from the template
    # def setup_security_manifest
    #   manifest_template = Tilt::ERBTemplate.new("templates/puppet/manifests/site_security.pp.erb", :trim => true)
    #   File.open("#{self.environment.project.path}/puppet/manifests/site.pp", 'w') do |f|
    #     f.write manifest_template.render(self.common_modules)
    #   end
    # end

    # # Generate the security hiera data from the template
    # def setup_security_common_hiera
    #   common_hiera_template = Tilt::ERBTemplate.new("templates/puppet/hiera/data/common_security.yaml.erb")
    #   File.open("#{self.environment.project.path}/puppet/hiera/data/common.yaml", 'w') do |f|
    #     f.write common_hiera_template.render(self)
    #   end
    # end

    # # Generate the PuppetModule objects array from the user module names choices array
    # def parse_common_modules(common_modules)
    #   common_modules_array = []
    #   yaml_modules = YAML.load(File.read('config/modules.yaml'))
    #   yaml_modules['common_modules'].each do |puppet_module, options|
    #     options = {} if options.nil?
    #     common_modules_array << Bebox::PuppetModule.new(options) if common_modules.include?(puppet_module)
    #   end
    #   common_modules_array
    # end
  end
end