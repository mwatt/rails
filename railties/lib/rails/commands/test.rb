require 'rails/commands/task_helpers'
require 'rails/test_unit/minitest_plugin'
require 'rake'

module Rails
  module Commands
    # This is a wrapper around all Rails test tasks, including:
    #   rails test
    #   rails test:db
    class Test
      include TaskHelpers

      attr_reader :argv

      COMMAND_WHITELIST = %w(test test:db)

      def initialize(argv)
        @argv = argv
      end

      def test
        if defined?(ENGINE_ROOT)
          $: << File.expand_path('test', ENGINE_ROOT)
        else
          $: << File.expand_path('../../test', APP_PATH)
        end

        exit Minitest.run(ARGV)
      end

      def test_db
        system("bin/rake test:db #{argv}")
      end
    end
  end
end
