require_relative 'common'
require 'rake'

module Rails
  module Commands
    module TaskBuilder
      # This is a wrapper around all Rails tmp tasks, including:
      #   rails tmp:clear
      #   rails tmp:create
      class Tmp
        include Common

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
end
