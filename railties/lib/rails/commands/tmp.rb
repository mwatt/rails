require 'rails/commands/task_helpers'
require 'rake'

module Rails
  module Commands
    # This is a wrapper around all Rails tmp tasks, including:
    #   rails tmp:clear
    #   rails tmp:create
    class Tmp
      include TaskHelpers

      attr_reader :argv

      COMMAND_WHITELIST = %w(tmp:clear tmp:create)

      def initialize(argv)
        @argv = argv
      end

      def tmp_clear
        system("bin/rake tmp:clear")
      end

      def tmp_create
        system("bin/rake tmp:create")
      end
    end
  end
end
