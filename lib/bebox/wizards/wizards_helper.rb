module Bebox
  module WizardsHelper
    # Ask for confirmation of any action
    def confirm_action?(message)
      require 'highline/import'
      quest message
      response =  ask(highline_quest('(y/n)')) do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Ask to write some input with validation
    def write_input(message, default=nil, validator=nil, not_valid_message=nil)
      require 'highline/import'
      response =  ask(highline_quest(message)) do |q|
        q.default = default if default
        q.validate = /\.(.*)/ if validator
        q.responses[:not_valid] = highline_warn(not_valid_message) if not_valid_message
      end
      return response
    end

    # Asks to choose an option
    def choose_option(options, question)
      require 'highline/import'
      choose do |menu|
        menu.header = title(question)
        options.each do |option|
          menu.choice(option)
        end
      end
    end

    # Check if the puppet resource has a valid name
    def valid_puppet_class_name?(name)
      valid_name = (name =~ /\A[a-z][a-z0-9_]*\Z/).nil? ? false : true
      valid_name && !Bebox::RESERVED_WORDS.include?(name)
    end
  end
end