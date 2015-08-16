require_relative 'common'
require 'rake'

module Rails
  module Commands
    module TaskBuilder
      # This is a wrapper around all Rails test tasks, including:
      #   rails test
      #   rails test:db
      #   rails test:javascript
      class Test
        include Common

        attr_reader :argv

        COMMAND_WHITELIST = %w(test test:db test:javascript)

        def initialize(argv)
          @argv = argv
        end

        # TODO: Modularize this -- only a proof of concept. Use 
        # Rake::Task[..].invoke!
        def test
          system("bin/rake test #{argv}")
        end

        def test_db
          system("bin/rake test:db #{argv}")
        end

        def test_javascript
          system("bin/rake test:javascript #{argv}")
        end
      end
    end
  end
end
