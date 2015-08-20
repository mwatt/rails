require 'rails/commands/task_helpers'
require 'rake'

module Rails
  module Commands
    # This is a wrapper around all Rails test tasks, including:
    #   rails test
    #   rails test:db
    class DevCache
      include TaskHelpers

      attr_reader :argv

      COMMAND_WHITELIST = %w(dev:cache)

      def initialize(argv)
        @argv = argv
      end

      def dev_cache
        system("bin/rake dev:cache")
      end
    end
  end
end
