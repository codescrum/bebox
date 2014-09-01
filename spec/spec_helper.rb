require 'simplecov'
SimpleCov.start
SimpleCov.start do
    require 'simplecov-badge'
    # add your normal SimpleCov configs
    add_filter "/app/admin/"
    # configure any options you want for SimpleCov::Formatter::BadgeFormatter
    SimpleCov::Formatter::BadgeFormatter.generate_groups = true
    SimpleCov::Formatter::BadgeFormatter.strength_foreground = true
    SimpleCov::Formatter::BadgeFormatter.timestamp = true
    # call SimpleCov::Formatter::BadgeFormatter after the normal HTMLFormatter
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
        SimpleCov::Formatter::HTMLFormatter,
        SimpleCov::Formatter::BadgeFormatter,
    ]
end

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