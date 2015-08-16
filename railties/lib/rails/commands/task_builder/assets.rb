require_relative 'common'
require 'rake'

module Rails
  module Commands
    module TaskBuilder
      # This is a wrapper around all Rails assets tasks, including:
      #   rails assets:clean
      #   rails assets:clobber
      #   rails assets:environment
      #   rails assets:precompile
      class Assets
        include Common

        attr_reader :argv

        COMMAND_WHITELIST = %w(assets:clean assets:clobber assets:environment 
          assets:precompile)

        def initialize(argv)
          @argv = argv
        end

        def assets_clean
          system("bin/rake assets:clean")
        end

        def assets_clobber
          system("bin/rake assets:clobber")
        end

        def assets_environment
          system("bin/rake assets:environment")
        end

        def assets_precompile
          system("bin/rake assets:precompile")
        end
      end
    end
  end
end
