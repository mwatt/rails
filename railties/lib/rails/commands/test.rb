require 'rails/test_unit/minitest_plugin'
require 'rails/commands/command'

module Rails
  module Commands
    # This is a wrapper around all Rails test tasks, including:
    #   rails test
    #   rails test:db
    class Test < Command
      def test
        system("bin/rake test")
      end

      def test_db
        system("bin/rake test:db")
      end
    end
  end
end
