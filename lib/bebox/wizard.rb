require_relative 'hosts'
require 'highline/import'
class Wizard
  attr_accessor :number_of_nodes, :hosts, :vbox_uri

  def self.process
    @hosts= []
    @number_of_machines = ask('number of nodes?'){ |q| q.default = 1 }
    host_validation
    @vbox_uri =  ask('vbox uri?')do |q|
      #q.validate = /\A\w+\Z/
      q.default = 'http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box'
    end

  end

  def self.host_validation
    eval(@number_of_machines).times do |number_node|
      begin
        answer = ask("ip and hostname for node #{number_node} ( 127.0.0.1, server1.project1.development )?") do |q|
          q.validate = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}, ?\w+\Z/
        end
        hosts_attributes = answer.split(',')
        ip = hosts_attributes[0].strip
        hostname = hosts_attributes[1].strip
        host = Host.new(ip: ip, hostname: hostname)
        unless host.valid?
          # TODO verify if the host is already taken.
          host.errors.full_messages.each{|message| puts message}
        end
      end while(!(host.valid?))
      @hosts << host
    end
  end
end
