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
require_relative '../lib/bebox/wizards/project_wizard'
require_relative '../lib/bebox/environment'
require_relative '../lib/bebox/wizards/environment_wizard'
require_relative '../lib/bebox/node'
require_relative '../lib/bebox/wizards/node_wizard'
require_relative '../lib/bebox/puppet'
require_relative '../lib/bebox/role'
require_relative '../lib/bebox/profile'

I18n.enforce_available_locales = false

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:each) do
    ENV['RUBY_ENV'] = 'test'
  end

  config.after(:each) do
      ENV['RUBY_ENV'] = 'development'
  end

  config.after(:suite) do
    # `rm -rf tmp/*`
  end

  # Factory Girl methods
  config.include FactoryGirl::Syntax::Methods
end