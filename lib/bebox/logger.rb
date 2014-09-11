
# A simple logger with colored output (logs to STDOUT)
module Bebox
  module Logger

    include FastGettext::Translation

    def self.included(base)
      base.extend(self)
    end

    def msg(message)
      puts message.white
    end

    def linebreak
      puts "\n"
    end

    def info(message)
      puts "\n#{message.yellow}\n\n"
    end

    def title(message)
      puts "\n#{message.cyan}\n\n"
    end

    def warn(message)
      puts "\n#{message.yellow}\n\n"
    end

    def error(message)
      puts "\n#{message.red}\n\n"
    end

    def quest(message)
      puts "\n#{message.magenta}"
    end

    def ok(message)
      puts "\n#{message.green}\n\n"
    end

    def highline_warn(message)
      "<%= color('#{message}', :yellow) %>"
    end

    def highline_quest(message)
      "<%= color('#{message}', :magenta) %>"
    end
  end
end