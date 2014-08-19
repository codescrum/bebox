module Bebox
  module WizardsHelper
    # Ask for confirmation of any action
    def confirm_action?(message)
      quest message
      response =  ask(highline_quest('(y/n)')) do |q|
        q.default = "n"
      end
      return response == 'y' ? true : false
    end

    # Asks to choose an option
    def choose_option(options, question)
      choose do |menu|
        menu.header = title(question)
        options.each do |option|
          menu.choice(option)
        end
      end
    end
  end
end