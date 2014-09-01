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

require_relative '../lib/bebox/logger'
require_relative '../lib/bebox/files_helper'
require_relative '../lib/bebox/wizards/wizards_helper'
require_relative '../lib/bebox/vagrant_helper'
require_relative '../lib/bebox/project'
require_relative '../lib/bebox/wizards/project_wizard'
require_relative '../lib/bebox/environment'
require_relative '../lib/bebox/node'
require_relative '../lib/bebox/wizards/node_wizard'
require_relative '../lib/bebox/provision'
require_relative '../lib/bebox/role'
require_relative '../lib/bebox/profile'
require_relative '../lib/bebox/vagrant_helper'

I18n.enforce_available_locales = false

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:each) do
    ENV['RUBY_ENV'] = 'test'
  end

  config.after(:each) do
      ENV['RUBY_ENV'] = 'development'
  end

  # Factory Girl methods
  config.include FactoryGirl::Syntax::Methods
end