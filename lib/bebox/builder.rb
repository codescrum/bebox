require 'tilt'
#require 'capistrano'
require "bebox/server"
module Bebox
  class Builder
    attr_accessor :project_name, :servers, :vbox_uri, :vagrant_box_base_name, :vagrant_box_provider, :current_pwd, :new_project_root, :local_hosts_file_location

    def initialize(project_name, servers, vbox_uri, vagrant_box_base_name, current_pwd = Dir.pwd, vagrant_box_provider = 'virtualbox')
      @current_pwd = current_pwd
      @project_name = project_name
      @servers = servers
      @vbox_uri= vbox_uri
      @vagrant_box_base_name = vagrant_box_base_name
      @vagrant_box_provider = vagrant_box_provider
      create_project_directory
      if  ENV['RUBY_ENV'].eql? 'test'
        @local_hosts_file_location = "#{@current_pwd}"
      else
        @local_hosts_file_location = RUBY_PLATFORM =~ /darwin/ ? '/private/etc' : '/etc'
      end
    end

    def vagrant_box_filename
      @vbox_uri.split('/').last
    end

    def build_vagrant_nodes
      create_directories
      create_files
    end

    def create_project_directory
      `cd #{@current_pwd} && mkdir -p #{@project_name}`
      @new_project_root = "#{@current_pwd}/#{@project_name}"
    end

    def create_directories
      `cd #{@new_project_root} && mkdir -p config && mkdir -p config/deploy && mkdir -p config/templates`
    end

    def create_files
      create_templates
      create_deploy_file
      add_vagrant_boxes
      generate_vagrantfile
    end

    # Generate the vagrantfile take into account the settings into vagrant hiera file
    def generate_vagrantfile
      template = Tilt::ERBTemplate.new("#{@new_project_root}/config/templates/Vagrantfile.erb")
      File.open("#{@new_project_root}/Vagrantfile", 'w') do |f|
        f.write template.render(@servers, :vagrant_box_base_name => @vagrant_box_base_name)
      end
    end

    # Add the specified boxes and init vagrant to create Vagrantfile
    def add_vagrant_boxes
      already_installed_boxes = installed_vagrant_box_names

      @servers.each_with_index do |server, index|
        box_name = "#{@vagrant_box_base_name}_#{index}"
        puts "  Adding server: #{server.hostname}..."
        `vagrant box add #{box_name} #{vagrant_box_filename}` unless already_installed_boxes.include? box_name
      end
    end


    # creates
    def create_deploy_file
      content = ''
      File::open("#{@new_project_root}/config/deploy.rb", "w")do |f|
        f.write(content)
      end
    end

    # creates a template
    def create_templates
      create_local_host_template
      create_vagrant_template
    end

    # creates a template
    def create_local_host_template
      content = File.read("templates/local_hosts.erb")
      File::open("#{@new_project_root}/config/templates/local_hosts.erb", "w")do |f|
        f.write(content)
      end
    end

    # creates a template
    def create_vagrant_template
      content = File.read("templates/Vagrantfile.erb")
      File::open("#{@new_project_root}/config/templates/Vagrantfile.erb", "w")do |f|
        f.write(content)
      end
    end

    # Modify the local hosts file
    def config_local_hosts_file
      sudo = (ENV['RUBY_ENV'].eql? 'test') ? '' : 'sudo'

      # Get the content of the hosts file
      hosts_content = File.read("#{@local_hosts_file_location}/hosts").gsub(/\s+/, ' ').strip

      # Make a backup of hosts file with the actual datetime
      hosts_backup_file = "#{@local_hosts_file_location}/hosts_#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}"
      `#{sudo} cp #{@local_hosts_file_location}/hosts #{hosts_backup_file}`

      # For each server it adds a line to the hosts file if this not exist
      @servers.each do |server|
        line = "#{server.ip} #{server.hostname}"
        server_present = (hosts_content =~ /#{server.ip}\s+#{server.hostname}/) ? true : false
        `#{sudo} echo '#{line}    # Added by bebox' | #{sudo} tee -a #{@local_hosts_file_location}/hosts` unless server_present
      end
      hosts_backup_file
    end

    # return an Array with the names of the currently installed vagrant boxes
    # @returns Array
    def installed_vagrant_box_names
      (`vagrant box list`).split("\n").map{|vagrant_box| vagrant_box.split(' ').first}
    end
  end
end