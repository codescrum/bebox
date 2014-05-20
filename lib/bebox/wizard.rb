require_relative 'server'
require_relative 'project'
require 'highline/import'
module Bebox
  class Wizard
    attr_accessor :number_of_nodes, :hosts, :vbox_uri,:vagrant_box_base_name, :vagrant_box_provider

    # Description
    # @return ..
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

      [@hosts, @vbox_uri, @vagrant_box_base_name]
      project = Bebox::Project.new(project_name, @hosts, @vbox_uri, @vagrant_box_base_name, Dir.pwd, @vagrant_box_provider)
      project.create
      project
    end

    # Description
    # @return ..
    def self.prepuppet_project(builder)
      pre_stages = ask('What stages do you want?. Comma separated (production,staging)') do |q|
        q.default = 'vagrant'
      end
      stages = pre_stages.split(',')
      stages << 'vagrant' unless pre_stages.include?('vagrant')
      prepuppet_builder = Bebox::PrepuppetBuilder.new(builder, stages)
    end

    # Description
    # @return ..
    def self.host_validation
      eval(@number_of_machines).times do |number_node|
        begin
          answer = ask("Ip and hostname for node #{number_node} ( 127.0.0.1, server1.project1.development )?") do |q|
            q.validate = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}, ?\w+\Z/
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
  end
end