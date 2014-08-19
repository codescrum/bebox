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
  end
end