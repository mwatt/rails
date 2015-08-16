require 'rails/commands/command'
require 'rake'

module Rails
  module Commands
    # This is a wrapper around all Rails assets tasks, including:
    #   rails assets:clean
    #   rails assets:clobber
    #   rails assets:environment
    #   rails assets:precompile
    class Assets < Command
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
