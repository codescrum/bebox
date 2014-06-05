require_relative 'server'
require_relative 'project'
require 'highline/import'
module Bebox
  class Wizard
    attr_accessor :number_of_nodes, :hosts, :vbox_uri,:vagrant_box_base_name, :vagrant_box_provider

    # Asks for the project parameters and create the project squeleton
    # @return project
    def self.create_new_project(project_name)
      @hosts= []
      @number_of_machines = ask('number of nodes?'){ |q| q.default = 1 }

      host_validation

      @vbox_uri =  ask('vbox uri?')do |q|
        # TODO q.validate = /\A\w+\Z/
        q.default = "#{Dir.pwd}/ubuntu-server-12042-x64-vbox4210-nocm.box"
      end

      @vagrant_box_base_name =  ask('vagrant box base name?') do |q|
        # TODO q.validate = /\A\w+\Z/
        q.default = "vagrant_#{project_name}"
      end

      @vagrant_box_provider = ask('vagrant box provider?') do |q|
        # TODO q.validate = /\A\w+\Z/
        q.default ='virtualbox'
      end

       pre_environments = ask('deploy environments?') do |q|
        # TODO q.validate = /\A\w+\Z/
        q.default ='vagrant'
      end

      environments = pre_environments.split(',')
      environments << 'vagrant' unless pre_environments.include?('vagrant')

      project = Bebox::Project.new(project_name, @hosts, @vbox_uri, @vagrant_box_base_name, Dir.pwd, @vagrant_box_provider, environments)
      project.create
      project
    end

    # Asks for the hostname an IP for each node until they are valid
    # @return array of Server objects
    def self.host_validation
      eval(@number_of_machines).times do |number_node|
        begin
          answer = ask("Ip and hostname for node #{number_node} ( 127.0.0.1, server1.project1.development )?") do |q|
            q.validate = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3},\s*\S+\Z/
          end
          hosts_attributes = answer.split(',')
          ip = hosts_attributes[0].strip
          hostname = hosts_attributes[1].strip
          host = Bebox::Server.new(ip: ip, hostname: hostname)
          unless host.valid?
            # TODO verify if the host is already taken.
            host.errors.full_messages.each{|message| puts message}
          end
        end while(!(host.valid?))
        @hosts << host
      end
    end

    # Asks for the what puppet modules include in the installation machine
    # @return array of string modules
    def self.setup_modules
      common_modules = []
      # Get the available modules from the modules yaml
      yaml_modules = YAML.load(File.read('config/modules.yaml'))
      available_modules = yaml_modules['common_modules'].keys

      # Asks for each module to be included
      say("what common modules do you want to include?")
      available_modules.each do |puppet_module|
        response =  ask("#{puppet_module} (y/n)")do |q|
          q.default = "n"
        end
        common_modules << puppet_module if response == 'y'
      end
      common_modules
    end
  end
end