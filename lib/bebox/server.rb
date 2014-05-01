require 'active_attr'
module Bebox
  class Server

    include ActiveAttr::Model

    attribute :ip
    attribute  :hostname
    attr_accessor :ip, :hostname
    I18n.enforce_available_locales = false

    def ip_free?
      pattern = Regexp.new("Destination Host Unreachable")
      ip_is_available =false
      `ping #{ip} -c 1 >> '#{ip}_ping.log'`
      file = File.read("#{ip}_ping.log")
      file.each_line do |line|
        if line.match(pattern)
          ip_is_available =  true
          break
        end
      end
      errors.add(:ip, 'is already taken!') unless ip_is_available
      remove_logs
      ip_is_available
    end

    def valid?
      ip_free? && valid_hostname?
    end

    def remove_logs
      `rm *_ping.log`
    end

    def valid_hostname?
      # reg server1.project_name.environment
      true
    end
  end
end