require 'active_attr'
module Bebox
  class Server

    include ActiveAttr::Model

    attribute :ip
    attribute  :hostname
    attr_accessor :ip, :hostname
    I18n.enforce_available_locales = false

    def ip_free?
      `ping -q -c 1 -W 3000 #{ip}`
      ip_is_available = ($?.exitstatus == 0) ? false : true
      errors.add(:ip, 'is already taken!') unless ip_is_available
      ip_is_available
    end

    def valid?
      ip_free? && valid_hostname?
    end

    def valid_hostname?
      # reg server1.project_name.environment
      true
    end
  end
end