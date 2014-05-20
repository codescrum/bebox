require 'rubygems'
require 'awesome_print'
require 'jazz_hands'
require 'pry'
require 'factory_girl'
require 'serverspec'
require 'pathname'
require 'net/ssh'

include Serverspec::Helper::Ssh
include Serverspec::Helper::Debian

require_relative '../lib/bebox/project'
require_relative '../lib/bebox/server'
# require_relative '../lib/bebox/prepuppet_builder'
require_relative '../spec/factories/server.rb'
require_relative '../spec/factories/project.rb'
# require_relative '../spec/factories/prepuppet_builder.rb'
I18n.enforce_available_locales = false


RSpec.configure do |config|
  # config.before do
  #   # host = File.basename(Pathname.new(example.metadata[:location]).dirname)
  #   host = 'server1.projectname.test'
  #   if config.host != host
  #   	config.disable_sudo = true
  #     config.ssh.close if config.ssh
  #     config.host  = host
  #     options = Net::SSH::Config.for(config.host)
  #     options[:keys] = %w(~/.vagrant.d/insecure_private_key)
		# 	options[:forward_agent] = true
  #     user = 'vagrant'
  #     config.ssh   = Net::SSH.start(config.host, user, options)
  #   end
  # end
	config.treat_symbols_as_metadata_keys_with_true_values = true

	config.before(:each) do
		ENV['RUBY_ENV'] = 'test'
	end

	config.after(:each) do
   		ENV['RUBY_ENV'] = 'development'
	end

  config.after(:all) do
    # `rm -rf tmp/*`
  end

	# Factory Girl methods
	config.include FactoryGirl::Syntax::Methods
end