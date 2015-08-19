require_relative 'common'

module Rails
  module Commands
    module TaskBuilder
      # This is a wrapper around all base Rails tasks, including but not
      # limited to: generate, console, server, test, dbconsole, new, etc.
      class Core
        include Common

        attr_reader :argv

        COMMAND_WHITELIST = %w(plugin generate destroy console server dbconsole
          runner new version help)

        def initialize(argv)
          @argv = argv
        end

        def require_command!(command)
          require "rails/commands/#{command}"
        end

        def plugin
          require_command!("plugin")
        end

        def generate_or_destroy(command)
          require 'rails/generators'
          require_application_and_environment!
          Rails.application.load_generators
          require_command!(command)
        end

        def generate
          generate_or_destroy(:generate)
        end

        def destroy
          generate_or_destroy(:destroy)
        end

        def console
          require_command!("console")
          options = Rails::Console.parse_arguments(argv)

          # RAILS_ENV needs to be set before config/application is required
          ENV['RAILS_ENV'] = options[:environment] if options[:environment]

          # shift ARGV so IRB doesn't freak
          shift_argv!

          require_application_and_environment!
          Rails::Console.start(Rails.application, options)
        end

        def server
          set_application_directory!
          require_command!("server")

          Rails::Server.new.tap do |server|
            # We need to require application after the server sets environment,
            # otherwise the --environment option given to the server won't propagate.
            require APP_PATH
            Dir.chdir(Rails.application.root)
            server.start
          end
        end

        def test
          require_command!("test")
        end

        def dbconsole
          require_command!("dbconsole")
          Rails::DBConsole.start
        end

        def runner
          require_command!("runner")
        end

        def new
          if %w(-h --help).include?(argv.first)
            require_command!("application")
          else
            exit_with_initialization_warning!
          end
        end

        def version
          argv.unshift '--version'
          require_command!("application")
        end

        private

          # Change to the application's path if there is no config.ru file in current directory.
          # This allows us to run `rails server` from other directories, but still get
          # the main config.ru and properly set the tmp directory.
          def set_application_directory!
            Dir.chdir(File.expand_path('../../', APP_PATH)) unless File.exist?(File.expand_path("config.ru"))
          end

          def require_application_and_environment!
            require APP_PATH
            Rails.application.require_environment!
          end
      end
    end
  end
end
