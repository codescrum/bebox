require 'rubygems'
require 'awesome_print'
require 'jazz_hands'
require 'pry'
require_relative '../lib/bebox/server'
require_relative '../lib/bebox/builder'
I18n.enforce_available_locales = false

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:each) do
    ENV['RUBY_ENV'] = 'test'
  end

  config.after(:each) do
   ENV['RUBY_ENV'] = 'development'
   `rm -rf tmp/*`
  end
end