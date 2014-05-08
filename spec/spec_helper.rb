require 'rubygems'
require 'awesome_print'
require 'jazz_hands'
require 'pry'
require 'factory_girl'

require_relative '../lib/bebox/server'
require_relative '../lib/bebox/builder'
require_relative '../lib/bebox/prepuppet_builder'
require_relative '../spec/factories/server.rb'
require_relative '../spec/factories/builder.rb'
require_relative '../spec/factories/prepuppet_builder.rb'
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

	# Factory Girl methods
	config.include FactoryGirl::Syntax::Methods
end