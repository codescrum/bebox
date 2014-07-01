require 'tilt'
# require 'bebox/puppet_module'
module Bebox

  PUPPET_STEPS = %w{step-0 step-1 step-2 step-3}

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
      if %w{step-0 step-1}.include?(self.step)
        copy_step_modules
        generate_hiera
      end
      # generate_puppetfile
      apply_step
      create_step_checkpoint
    end

    # Copy the static modules to the step-N modules path
    def copy_step_modules
      `cp -r #{Bebox::Puppet::templates_path}/puppet/#{self.step}/modules/* #{self.project_root}/puppet/steps/#{Bebox::Puppet.step_name(self.step)}/modules/`
    end

    # Generate the hiera data for step from the template
    def generate_hiera
      ssh_key = Bebox::Project.public_ssh_key_from_file(self.project_root, self.environment)
      project_name = Bebox::Project.name_from_file(self.project_root)
      hiera_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{self.step}/hiera/hiera.yaml.erb")
      File.open("#{self.project_root}/puppet/steps/#{Bebox::Puppet.step_name(self.step)}/hiera/hiera.yaml", 'w') do |f|
        f.write hiera_template.render(nil, :step_dir => Bebox::Puppet.step_name(self.step))
      end
      common_hiera_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{self.step}/hiera/data/common_apply.yaml.erb")
      File.open("#{self.project_root}/puppet/steps/#{Bebox::Puppet.step_name(self.step)}/hiera/data/common.yaml", 'w') do |f|
        f.write common_hiera_template.render(nil, :ssh_key => ssh_key, :project_name => project_name)
      end
    end

    # Generate the site.pp for step
    def self.generate_manifests(project_root, step, nodes)
      manifest_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{step}/manifests/site_apply.pp.erb", :trim => true)
      File.open("#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp", 'w') do |f|
        f.write manifest_template.render(nil, :nodes => nodes)
      end
    end

    def self.generate_hiera_for_steps(project_root, template_file, filename, options)
      Bebox::PUPPET_STEPS.each do |step|
        step_dir = Bebox::Puppet.step_name(step)
        hiera_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{step}/hiera/data/#{template_file}")
        File.open("#{project_root}/puppet/steps/#{step_dir}/hiera/data/#{filename}.yaml", 'w') do |f|
          f.write hiera_template.render(nil, options)
        end
      end
    end

    # Generate the Puppetfile from the template
    def generate_puppetfile
      puppetfile_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{self.step}/Puppetfile.erb", :trim => true)
      File.open("#{self.project_root}/puppet/steps/#{Bebox::Puppet.step_name(self.step)}/Puppetfile", 'w') do |f|
        f.write puppetfile_template.render(nil)
      end
    end

    # Set a role for a node in the step-2 manifests file
    def self.associate_node_role(project_root, environment, node_name, role_name)
      # Create the manifests site.pp file for step-2 if not exist
      unless Bebox::Puppet.manifests_exists?(project_root, 'step-2')
        nodes = Bebox::Node.nodes_in_environment(project_root, environment, 'nodes')
        Bebox::Puppet.generate_manifests(project_root, self.step, nodes)
      end
      # Set the role for a node
      Bebox::Puppet.remove_role(project_root, node_name, 'step-2')
      Bebox::Puppet.add_role(project_root, node_name, role_name)
    end

    # Add a node to site.pp
    def self.add_node_to_step_manifests(project_root, node)
      Bebox::PUPPET_STEPS.each do |step|
        Bebox::Puppet.remove_node(project_root, node.hostname, step)
        manifest_path = "#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp"
        content = File.read(manifest_path)
        content += "\nnode #{node.hostname} {\n\n}\n"
        File.open(manifest_path, 'wb') { |file| file.write(content) }
      end
    end

    # Remove hiera data file for node
    def self.remove_hiera_for_steps(project_root, node_name)
      Bebox::PUPPET_STEPS.each do |step|
        `cd #{project_root} && rm -rf #{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/hiera/data/#{node_name}.yaml`
      end
    end

    # Remove node in manifests file for each step
    def self.remove_node_for_steps(project_root, node_name)
      Bebox::PUPPET_STEPS.each do |step|
        Bebox::Puppet.remove_node(project_root, node_name, step)
      end
    end

    # Add a role to a node
    def self.add_role(project_root, node_name, role_name)
      tempfile_path = "#{project_root}/puppet/steps/#{Bebox::Puppet.step_name('step-2')}/manifests/site.pp.tmp"
      manifest_path = "#{project_root}/puppet/steps/#{Bebox::Puppet.step_name('step-2')}/manifests/site.pp"
      tempfile = File.open(tempfile_path, 'w')
      manifest_file = File.new(manifest_path)
      manifest_file.each do |line|
        line << "\n  include role::#{role_name}\n" if (line =~ /^\s*node\s+#{node_name}\s+{\s*$/)
        tempfile << line
      end
      manifest_file.close
      tempfile.close
      FileUtils.mv(tempfile_path, manifest_path)
    end

    # Remove the current role in a node
    def self.remove_node(project_root, node_name, step)
      manifest_path = "#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp"
      regexp = /^\s*node\s+#{node_name}\s*({.*?}\s*)/m
      content = File.read(manifest_path).sub(regexp, '')
      File.open(manifest_path, 'wb') { |file| file.write(content) }
    end

    # Remove the current role in a node
    def self.remove_role(project_root, node_name, step)
      manifest_path = "#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp"
      regexp = /^\s*node\s+#{node_name}\s*({.*?}\s*)/m
      content = File.read(manifest_path).sub(regexp, "node #{node_name} {\n\n}\n")
      File.open(manifest_path, 'wb') { |file| file.write(content) }
    end

    # Check if a manifests for a step exist
    def self.manifests_exists?(project_root, step)
      File.exist?("#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp")
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

    # # Download the modules in the puppet user machine through librarian puppet
    # def bundle_modules
    #   `cd #{self.environment.project.path} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment.name} puppet:bundle_modules -s phase='bundle_modules'`
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