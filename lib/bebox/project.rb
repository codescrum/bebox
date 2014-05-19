require 'tilt'
require "bebox/server"
module Bebox
  class Project

		attr_accessor :name, :servers, :vbox_uri, :vagrant_box_base_name, :vagrant_box_provider, :parent_path, :path, :local_hosts_file_location

    def initialize(name, servers, vbox_uri, vagrant_box_base_name, parent_path = Dir.pwd, vagrant_box_provider = 'virtualbox')
      self.name = name
      self.servers = servers
      self.vbox_uri= vbox_uri
      self.vagrant_box_base_name = vagrant_box_base_name
      self.vagrant_box_provider = vagrant_box_provider
      self.parent_path = parent_path
      self.path = "#{self.parent_path}/#{self.name}"
      self.local_hosts_file_location = RUBY_PLATFORM =~ /darwin/ ? '/private/etc' : '/etc'
    end

    def create
    	create_project_directory
    	create_subdirectories
    end

    def create_project_directory
      `cd #{self.parent_path} && mkdir -p #{self.name}`
    end

    def create_subdirectories
      `cd #{self.path} && mkdir -p config && mkdir -p config/deploy`
    end
  end
end