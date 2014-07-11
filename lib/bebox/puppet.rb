require 'tilt'
require 'pry'

module Bebox

  PUPPET_STEPS = %w{step-0 step-1 step-2 step-3}
  PUPPET_STEP_NAMES = %w{0-fundamental 1-users 2-services 3-security}

  class Puppet

    attr_accessor :environment, :project_root, :node, :step

    def initialize(project_root, environment, node, step)
      self.project_root = project_root
      self.environment = environment
      self.node = node
      self.step = step
    end

    # Puppet apply Fundamental step
    def apply
      check_puppetfile_content
      copy_static_modules
      process_status = apply_step
      create_step_checkpoint if process_status.success?
      process_status
    end

    # Check if it's necessary a Puppetfile accord to it's content
    def check_puppetfile_content
      puppetfile_content = File.read("#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/Puppetfile").strip
      `rm "#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/Puppetfile"` if puppetfile_content.scan(/^\s*(mod\s*.+?)$/).flatten.empty?
    end

    # Copy the static modules to the step-N modules path
    def copy_static_modules
      `cp -R #{Bebox::Puppet::templates_path}/puppet/#{self.step}/modules/* #{self.project_root}/puppet/steps/#{Bebox::Puppet.step_name(self.step)}/modules/`
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

    # Generate the roles and profiles modules for the step
    def self.generate_roles_and_profiles(project_root, step, role, profiles)
      # Re-create the roles and profiles module directories
      `rm -rf #{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/modules/{roles,profiles}`
      `mkdir -p #{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/modules/{roles,profiles}/manifests`
      # Copy role to module
      `cp #{project_root}/puppet/roles/#{role}/manifests/init.pp #{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/modules/roles/manifests/#{role}.pp`
      # Copy profiles to module
      profiles.each do |profile|
        `cp #{project_root}/puppet/profiles/#{profile}/manifests/init.pp #{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/modules/profiles/manifests/#{profile}.pp`
      end
    end

    # Generate the Puppetfile from the role-profiles partial puppetfiles
    def self.generate_puppetfile(project_root, step, profiles)
      modules = []
      puppetfile_path = "#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/Puppetfile"
      profiles.each do |profile|
        profile_puppetfile_path = "#{project_root}/puppet/profiles/#{profile}/Puppetfile"
        puppetfile_content = File.read(profile_puppetfile_path)
        modules << puppetfile_content.scan(/^\s*(mod\s*.+?)$/).flatten
      end
      puppetfile_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{step}/Puppetfile.erb", :trim => true)
      File.open("#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/Puppetfile", 'w') do |f|
        f.write puppetfile_template.render(nil, :profile_modules => modules.flatten)
      end
    end

    # Get the role name associated with a node
    def self.role_from_node(project_root, step, node)
      manifest_path = "#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp"
      manifest_content = File.read(manifest_path)
      matching_nodes = manifest_content.match(/^\s*node\s+#{node}\s*({.*?}\s*)/m)
      unless matching_nodes.nil?
        matching_role = matching_nodes[0].strip.match(/roles::(.+?$)/)
        role = matching_role[1] unless matching_role.nil?
      end
      role
    end

    # Get the profiles names array associated with a role
    def self.profiles_from_role(project_root, role_name)
      profiles = []
      role_path = "#{project_root}/puppet/roles/#{role_name}/manifests/init.pp"
      role_content = File.read(role_path)
      matching_roles = role_content.match(/^\s*class\s+roles::#{role_name}\s*({.*?}\s*)/m)
      profiles = matching_roles[0].strip.scan(/profiles::(.+?$)/).flatten unless matching_roles.nil?
      profiles
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
        manifest_node_template = Tilt::ERBTemplate.new("#{Bebox::Puppet::templates_path}/puppet/#{step}/manifests/node.erb", :trim => true)
        manifest_node = manifest_node_template.render(nil, :node => node)
        Bebox::Puppet.remove_node(project_root, node.hostname, step)
        manifest_path = "#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp"
        content = File.read(manifest_path)
        content += "\n#{manifest_node}\n"
        File.open(manifest_path, 'wb') { |file| file.write(content) }
      end
    end

    # Remove hiera data file for node
    def self.remove_hiera_for_steps(project_root, node_name)
      Bebox::PUPPET_STEP_NAMES.each do |step|
        `cd #{project_root} && rm -rf #{project_root}/puppet/steps/#{step}/hiera/data/#{node_name}.yaml`
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
        line << "\n  include roles::#{role_name}\n" if (line =~ /^\s*node\s+#{node_name}\s+{\s*$/)
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
      content = File.read(manifest_path).sub(regexp, "\nnode #{node_name} {\n\n}\n\n")
      File.open(manifest_path, 'wb') { |file| file.write(content) }
    end

    # Check if a manifests for a step exist
    def self.manifests_exists?(project_root, step)
      File.exist?("#{project_root}/puppet/steps/#{Bebox::Puppet.step_name(step)}/manifests/site.pp")
    end

    # Apply step via capistrano
    def apply_step
      cap 'deploy:setup'
      $?.success? ? (cap 'deploy') : (return $?)
      $?.success? ? (cap 'puppet:bundle_modules') : (return $?)
      $?.success? ? (cap 'puppet:apply') : (return $?)
      $?
    end

    # Executes capistrano commands
    def cap(command)
      `cd #{self.project_root} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{self.environment} #{command} -S phase='#{self.step}' -S step_dir='#{step_name}' HOSTS=#{self.node.hostname}`
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

    def step_name
      Bebox::Puppet.step_name(self.step)
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
  end
end