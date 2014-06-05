module Bebox
  class PuppetModule

    attr_accessor :version, :puppet_name ,:git, :ref, :include_name

    def initialize( options = {})
      options.each { |k,v| send("#{k}=",v) }
    end
  end
end