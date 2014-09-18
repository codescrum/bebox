
module Bebox

  PROVISION_STEPS = %w{step-0 step-1 step-2 step-3}
  RESERVED_WORDS = %w{and case class default define else elsif false if in import inherits node or true undef unless main settings}

  class Provision

    include Bebox::FilesHelper

    attr_accessor :environment, :project_root, :node, :step, :started_at, :finished_at

    def initialize(project_root, environment, node, step)
      self.project_root = project_root
      self.environment = environment
      self.node = node
      self.step = step
    end

    # Puppet apply Fundamental step
    def apply
      started_at = DateTime.now.to_s
      # Check if a Puppetfile is neccesary for use/not use librarian-puppet
      check_puppetfile_content
      # Copy static modules that are not downloaded by librarian-puppet
      copy_static_modules
      # Apply step and if the process is succesful create the checkpoint.
      process_status = apply_step
      create_step_checkpoint(started_at) if process_status.success?
      process_status
    end

    # Check if it's necessary a Puppetfile accord to it's content
    def check_puppetfile_content
      puppetfile_content = File.read("#{project_root}/puppet/steps/#{step}/Puppetfile").strip
      (FileUtils.rm "#{project_root}/puppet/steps/#{step}/Puppetfile", force: true) if puppetfile_content.scan(/^\s*(mod\s*.+?)$/).flatten.empty?
    end

    # Copy the static modules to the step-N modules path
    def copy_static_modules
      modules_path = "#{Bebox::FilesHelper::templates_path}/puppet/#{step}/modules"
      FileUtils.cp_r "#{modules_path}/.", "#{self.project_root}/puppet/steps/#{step}/modules" unless Dir.glob(modules_path).empty?
    end

    # Generate the hiera templates for each step
    def self.generate_hiera_for_steps(project_root, template_file, filename, options)
      Bebox::PROVISION_STEPS.each{ |step| generate_file_from_template("#{Bebox::FilesHelper::templates_path}/puppet/#{step}/hiera/data/#{template_file}",
        "#{project_root}/puppet/steps/#{step}/hiera/data/#{filename}.yaml", options) }
    end

    # Generate the roles and profiles modules for the step
    def self.generate_roles_and_profiles(project_root, step, role, profiles)
      modules_path = "#{project_root}/puppet/steps/#{step}/modules"
      # Re-create the roles and profiles puppet module directories
      %w{roles profiles}.each{ |dir| FileUtils.rm "#{modules_path}/#{dir}", force: true }
      %w{roles/manifests profiles/manifests}.each{ |dir| FileUtils.mkdir_p "#{modules_path}/#{dir}", force: true }
      # Copy role to puppet roles module
      FileUtils.cp_r "#{project_root}/puppet/roles/#{role}/manifests/init.pp", "#{modules_path}/roles/manifests/#{role}.pp"
      # Copy profiles to puppet profiles module
      profiles.each do |profile|
        profile_tree = profile.gsub('::','/')
        profile_tree_parent = profile_tree.split('/')[0...-1].join('/')
        profile_path = "#{modules_path}/profiles/manifests"
        FileUtils.mkdir_p "#{profile_path}/#{profile_tree_parent}"
        FileUtils.cp_r "#{project_root}/puppet/profiles/#{profile_tree}/manifests/init.pp", "#{profile_path}/#{profile_tree}.pp"
      end
    end

    # Generate the Puppetfile from the role-profiles partial puppetfiles
    def self.generate_puppetfile(project_root, step, profiles)
      modules = []
      profiles.each do |profile|
        profile_puppetfile_path = "#{project_root}/puppet/profiles/#{profile.gsub('::','/')}/Puppetfile"
        puppetfile_content = File.read(profile_puppetfile_path)
        modules << puppetfile_content.scan(/^\s*(mod\s*.+?)$/).uniq
      end
      generate_file_from_template("#{Bebox::FilesHelper::templates_path}/puppet/#{step}/Puppetfile.erb", "#{project_root}/puppet/steps/#{step}/Puppetfile", {profile_modules: modules.flatten})
    end

    # Get the role name associated with a node
    def self.role_from_node(project_root, step, node)
      manifest_path = "#{project_root}/puppet/steps/#{step}/manifests/site.pp"
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
      Bebox::Provision.remove_role(project_root, node_name, 'step-2')
      Bebox::Provision.add_role(project_root, node_name, role_name)
    end

    # Add a node to site.pp
    def self.add_node_to_step_manifests(project_root, node)
      Bebox::PROVISION_STEPS.each do |step|
        manifest_node = render_erb_template("#{Bebox::FilesHelper::templates_path}/puppet/#{step}/manifests/node.erb", {node: node})
        Bebox::Provision.remove_node(project_root, node.hostname, step)
        manifest_path = "#{project_root}/puppet/steps/#{step}/manifests/site.pp"
        content = File.read(manifest_path)
        content += "\n#{manifest_node}\n"
        write_content_to_file(manifest_path, content)
      end
    end

    # Remove hiera data file for node
    def self.remove_hiera_for_steps(project_root, node_name)
      Bebox::PROVISION_STEPS.each{ |step| FileUtils.rm "#{project_root}/puppet/steps/#{step}/hiera/data/#{node_name}.yaml", :force => true }
    end

    # Remove node in manifests file for each step
    def self.remove_node_for_steps(project_root, node_name)
      Bebox::PROVISION_STEPS.each { |step| Bebox::Provision.remove_node(project_root, node_name, step) }
    end

    # Add a role to a node
    def self.add_role(project_root, node_name, role_name)
      manifest_path = "#{project_root}/puppet/steps/step-2/manifests/site.pp"
      tempfile_path = "#{manifest_path}.tmp"
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
      manifest_path = "#{project_root}/puppet/steps/#{step}/manifests/site.pp"
      regexp = /^\s*node\s+#{node_name}\s*({.*?}\s*)/m
      content = File.read(manifest_path).sub(regexp, '')
      File.open(manifest_path, 'wb') { |file| file.write(content) }
    end

    # Remove the current role in a node
    def self.remove_role(project_root, node_name, step)
      manifest_path = "#{project_root}/puppet/steps/#{step}/manifests/site.pp"
      regexp = /^\s*node\s+#{node_name}\s*({.*?}\s*)/m
      content = File.read(manifest_path).sub(regexp, "\nnode #{node_name} {\n\n}\n\n")
      File.open(manifest_path, 'wb') { |file| file.write(content) }
    end

    # Apply step via capistrano in the machine
    def apply_step
      # Create deploy directories
      cap 'deploy:setup'
      # Deploy the configured step
      $?.success? ? (cap 'deploy') : (return $?)
      # Download dynamic step modules through librarian-puppet
      $?.success? ? (cap 'puppet:bundle_modules') : (return $?)
      # Install the step provision through puppet
      $?.success? ? (cap 'puppet:apply') : (return $?)
      $?
    end

    # Executes capistrano commands
    def cap(command)
      `cd #{self.project_root} && BUNDLE_GEMFILE=Gemfile bundle exec cap #{command} -S phase='#{step}' -S step_dir='#{step}' -S environment=#{environment} HOSTS=#{self.node.hostname}`
    end

    # Create checkpoint for step
    def create_step_checkpoint(started_at)
      self.node.started_at = started_at
      self.node.finished_at = DateTime.now.to_s
      generate_file_from_template("#{Bebox::FilesHelper::templates_path}/node/provisioned_node.yml.erb",
        "#{self.project_root}/.checkpoints/environments/#{self.environment}/phases/phase-2/steps/#{self.step}/#{self.node.hostname}.yml", {node: self.node})
    end
  end
end