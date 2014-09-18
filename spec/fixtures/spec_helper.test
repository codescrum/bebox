require 'factory_girl'
require 'ostruct'
require 'serverspec'
require 'pathname'
require 'net/ssh'

include Serverspec::Helper::Ssh
include Serverspec::Helper::Debian

RSpec.configure do |config|

  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:each) do
    ENV['RUBY_ENV'] = 'test'
  end

  # Factory Girl methods
  config.include FactoryGirl::Syntax::Methods

  # Do this so that factories are loaded
  config.before(:suite) { FactoryGirl.reload }
end