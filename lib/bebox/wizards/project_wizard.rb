
module Bebox
  class ProjectWizard
    include Bebox::Logger
    include Bebox::WizardsHelper
    # Bebox boxes directory
    BEBOX_BOXES_PATH = '~/.bebox/boxes'

    # Asks for the project parameters and create the project skeleton
    def create_new_project(project_name)
      # Check project existence
      return error('Project not created. There is already a project with that name in the current directory.') if project_exists?(Dir.pwd, project_name)
      # Setup the bebox boxes directory
      bebox_boxes_setup
      # Asks to choose an existing box
      current_box = choose_box(get_existing_boxes)
      vagrant_box_base = "#{BEBOX_BOXES_PATH}/#{get_valid_box_uri(current_box)}"
      # Asks user to choose vagrant box provider
      vagrant_box_provider = choose_option(%w{virtualbox vmware}, 'Choose the vagrant box provider')
      # Set default environments
      default_environments = %w{vagrant staging production}
      # Project creation
      project = Bebox::Project.new(project_name, vagrant_box_base, Dir.pwd, vagrant_box_provider, default_environments)
      output = project.create
      ok "Project '#{project_name}' created!.\nMake: cd #{project_name}\nNow you can add new environments or new nodes to your project.\nSee bebox help."
      return output
    end

    # If choose to download/select new box get a valid uri
    def get_valid_box_uri(current_box)
      return current_box unless current_box.nil?
      # Keep asking for valid uri or overwriting until confirmation
      confirm = false
      begin
        # Asks vagrant box location to user if not choose an existing box
        valid_box_uri = ask_uri
        # Confirm if the box already exist
        confirm = box_exists?(valid_box_uri) ? confirm_action?('There is already a box with that name, do you want to overwrite it?') : true
      end while !confirm
      # Setup the box with the valid uri
      set_box(valid_box_uri)
    end

    # Check if there's an existing project in that dir
    def project_exists?(parent_path, project_name)
      Dir.exists?("#{parent_path}/#{project_name}")
    end

    # Setup the bebox boxes directory
    def bebox_boxes_setup
      # Create user project directories
      `mkdir -p #{BEBOX_BOXES_PATH}/tmp`
      # Clear partial downloaded boxes
      `rm -f #{BEBOX_BOXES_PATH}/tmp/*`
    end

    # Asks vagrant box location to user until is valid
    def ask_uri
      vbox_uri = write_input('Write the URI (http, local_path) for the vagrant box to be used in the project:', 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box')
      # If valid return uri if not keep asking for uri
      uri_valid?(vbox_uri) ? (return vbox_uri) : ask_uri
    end

    # Setup the box in the bebox boxes directory
    def set_box(box_uri)
      require 'uri'
      uri = URI.parse(box_uri)
      if %w{http https}.include?(uri.scheme)
        info 'Downloading box ...'
        download_box(uri)
      else
        `ln -fs #{uri.path} #{BEBOX_BOXES_PATH}/#{uri.path.split('/').last}`
      end
    end

    # Validate uri download or local box existence
    def uri_valid?(vbox_uri)
      require 'uri'
      uri = URI.parse(vbox_uri)
      %w{http https}.include?(uri.scheme) ? http_uri_valid?(uri) : file_uri_valid?(uri)
    end

    def http_uri_valid?(uri)
      require 'net/http'
      request = Net::HTTP.new uri.host
      response = request.request_head uri.path
      error('Redirections not supported.') if response.code.to_i == 302
      ( response.code.to_i == 200) ? (return true) : error('Download link not valid!.')
    end

    def file_uri_valid?(uri)
      File.file?(uri.path) ? (return true) : error('File path not exist!.')
    end

    # Check if a box with the same name already exist
    def box_exists?(valid_box_uri)
      box_name = valid_box_uri.split('/').last
      boxes = get_existing_boxes
      boxes.any? { |val| /#{box_name}/ =~ val }
    end

    # Obtain the current boxes downloaded or linked in the bebox user home
    def get_existing_boxes
      # Converts the bebox boxes directory to an absolute pathname
      expanded_directory = File.expand_path("#{BEBOX_BOXES_PATH}")
      # Get an array of bebox boxes paths
      boxes = Dir["#{expanded_directory}/*"].reject {|f| File.directory? f}
      boxes.map{|box| box.split('/').last}
    end

    # Asks to choose an existing box in the bebox boxes directory
    def choose_box(boxes)
      # Menu to choose vagrant box provider
      other_box_message = 'Download/Select a new box'
      boxes << other_box_message
      current_box = choose_option(boxes, 'Choose an existing box or download/select a new box')
      current_box = (current_box == other_box_message) ? nil : current_box
    end

    # Download a box by the specified uri
    def download_box(uri)
      @counter = 0
      url = uri.path
      file_name = uri.path.split('/').last
      expanded_directory = File.expand_path(BEBOX_BOXES_PATH)
      # Download file to bebox boxes tmp
      require 'net/http'
      require 'uri'
      Net::HTTP.start(uri.host) do |http|
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
  end
end