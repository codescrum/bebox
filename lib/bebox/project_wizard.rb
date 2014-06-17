# require_relative 'server'
require_relative 'project'
require 'highline/import'
require 'net/http'
require 'uri'
require 'progressbar'
require 'digest'
require 'pry'

module Bebox
  class ProjectWizard

    # Bebox boxes directory
    BEBOX_BOXES_PATH = '~/.bebox/boxes'

    def self.bebox_boxes_path
      BEBOX_BOXES_PATH
    end

    # Asks for the project parameters and create the project skeleton
    def self.create_new_project(project_name)
      # Check project existence
      return 'Project not created. There\'s already a project with that name in the current directory.!' if project_exists?(Dir.pwd, project_name)
      # Setup the bebox boxes directory
      bebox_boxes_setup
      # Asks to choose an existent box
      current_box = choose_box(get_existent_boxes)
      # If choose to download/select new box
      if current_box.nil?
        # Keep asking for valid uri or overwriting until confirmation
        confirm = false
        begin
          # Asks vagrant box location to user if not choose an existent box
          valid_box_uri = ask_uri
          # Confirm if the box already exist
          confirm = box_exists?(valid_box_uri) ? confirm_overwrite? : true
        end while !confirm
        # Setup the box with the valid uri
        set_box(valid_box_uri)
      else
        valid_box_uri = current_box
      end
      vagrant_box_base = "#{BEBOX_BOXES_PATH}/#{valid_box_uri}"
      # Asks user to choose vagrant box provider
      vagrant_box_provider = ask_box_provider
      # Set default environments
      default_environments = %w{vagrant staging production}
      # Project creation
      project = Bebox::Project.new(project_name, vagrant_box_base, Dir.pwd, vagrant_box_provider, default_environments)
      project.create
      return "Project #{project_name} created!.\nMake: cd test\nNow you can add new environments or new nodes to your project.\nSee bebox help."
    end

    # Check if there's an existent project in that dir
    def self.project_exists?(parent_path, project_name)
      Dir.exists?("#{parent_path}/#{project_name}")
    end

    # Menu to choose vagrant box provider
    def self.ask_box_provider
      choose do |menu|
        menu.header = 'Choose the vagrant box provider'
        menu.choices('virtualbox', 'vmware')
      end
    end

    # Setup the bebox boxes directory
    def self.bebox_boxes_setup
      # Create user project directories
      `mkdir -p #{BEBOX_BOXES_PATH}/tmp`
      # Clear partial downloaded boxes
      `rm -f #{BEBOX_BOXES_PATH}/tmp/*`
    end

    # Asks vagrant box location to user until is valid
    def self.ask_uri
      vbox_uri =  ask('Write the URI (http, local_path) for the vagrant box to be used in the project:') do |q|
        q.default = 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'
      end
      # If valid return uri if not keep asking for uri
      uri_valid?(vbox_uri) ? (return vbox_uri) : ask_uri
    end

    # Setup the box in the bebox boxes directory
    def self.set_box(box_uri)
      uri = URI.parse(box_uri)
      if uri.scheme == ('http' || 'https')
        download_box(uri)
      else
        file_name = uri.path.split('/').last
        `ln -fs #{uri.path} #{BEBOX_BOXES_PATH}/#{file_name}`
      end
    end

    # Validate uri download or local box existence
    def self.uri_valid?(vbox_uri)
      uri = URI.parse(vbox_uri)
      if uri.scheme == ('http' || 'https')
        request = Net::HTTP.new uri.host
        response = request.request_head uri.path
        if response.code.to_i == 302
          uri = URI.parse(response['location'])
          request = Net::HTTP.new uri.host
          response = request.request_head uri.path
        end
        ( response.code.to_i == 200) ? (return true) : say('Download link not valid!.')
      else
        File.file?(uri.path) ? (return true) : say('File path not exist!.')
      end
    end

    # Ask for confirmation of overwrite a box
    def self.confirm_overwrite?
      say('There\'s already a box with that name, do you want to overwrite it?')
      response =  ask("(y/n)")do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Check if a box with the same name already exist
    def self.box_exists?(valid_box_uri)
      box_name = valid_box_uri.split('/').last
      boxes = get_existent_boxes
      boxes.any? { |val| /#{box_name}/ =~ val }
    end

    # Obtain the current boxes downloaded or linked in the bebox user home
    def self.get_existent_boxes
      # Converts the bebox boxes directory to an absolute pathname
      expanded_directory = File.expand_path("#{BEBOX_BOXES_PATH}")
      # Get an array of bebox boxes paths
      Dir["#{expanded_directory}/*"].reject {|f| File.directory? f}
    end

    # Asks to choose an existent box in the bebox boxes directory
    def self.choose_box(boxes)
      # Menu to choose vagrant box provider
      other_box_message = 'Download/Select a new box'
      current_box = choose do |menu|
        menu.header = 'Choose an existent box or download/select a new box'
        boxes.each do |box|
          menu.choice(box.split('/').last)
        end
        menu.choice(other_box_message)
      end
      current_box = (current_box == other_box_message) ? nil : current_box
    end

    # Download a box by the specified uri
    def self.download_box(uri)
      say('Downloading box ...')
      @counter = 0
      # Manage redirections
      request = Net::HTTP.new uri.host
      response = request.request_head uri.path
      uri = URI.parse(response['location']) if response.code.to_i == 302

      # Set url variables
      url = uri.path
      url_base = uri.host
      file_name = uri.path.split('/').last
      expanded_directory = File.expand_path("#{BEBOX_BOXES_PATH}")

      # Download file to bebox boxes tmp
      Net::HTTP.start(url_base) do |http|
        response = http.request_head(URI.escape(url))
        ProgressBar
        pbar = ProgressBar.new('file name:', response['content-length'].to_i)
        File.open("#{expanded_directory}/tmp/#{file_name}", 'w') {|f|
          http.get(URI.escape(url)) do |str|
            f.write str
            @counter += str.length
            pbar.set(@counter)
          end
        }
        # In download completion move from tmp to bebox boxes dir
        pbar.finish
        `mv #{BEBOX_BOXES_PATH}/tmp/#{file_name} #{BEBOX_BOXES_PATH}/`
      end
    end

    # # Asks for the hostname an IP for each node until they are valid
    # # @return array of Server objects
    # def self.host_validation
    #   eval(@number_of_machines).times do |number_node|
    #     begin
    #       answer = ask("Ip and hostname for node #{number_node} ( 127.0.0.1, server1.project1.development )?") do |q|
    #         q.validate = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3},\s*\S+\Z/
    #       end
    #       hosts_attributes = answer.split(',')
    #       ip = hosts_attributes[0].strip
    #       hostname = hosts_attributes[1].strip
    #       host = Bebox::Server.new(ip: ip, hostname: hostname)
    #       unless host.valid?
    #         # TODO verify if the host is already taken.
    #         host.errors.full_messages.each{|message| puts message}
    #       end
    #     end while(!(host.valid?))
    #     @hosts << host
    #   end
    # end

    # # Asks for the what puppet modules include in the installation machine
    # # @return array of string modules
    # def self.setup_modules
    #   common_modules = []
    #   # Get the available modules from the modules yaml
    #   yaml_modules = YAML.load(File.read('config/modules.yaml'))
    #   available_modules = yaml_modules['common_modules'].keys

    #   # Asks for each module to be included
    #   say("what common modules do you want to include?")
    #   available_modules.each do |puppet_module|
    #     response =  ask("#{puppet_module} (y/n)")do |q|
    #       q.default = "n"
    #     end
    #     common_modules << puppet_module if response == 'y'
    #   end
    #   common_modules
    # end
  end
end