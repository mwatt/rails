require 'rails/commands/assets'
require 'rails/commands/command'
require 'rails/commands/core'
require 'rails/commands/db'
require 'rails/commands/dev_cache'
require 'rails/commands/test'
require 'rails/commands/tmp'

module Rails
  # This is a class which takes in a rails command and initiates the appropriate
  # initiation sequence.
  #
  # Warning: This class mutates ARGV because some commands require manipulating
  # it before they are run.
  class CommandsTasks # :nodoc:
    attr_reader :argv

    HELP_MESSAGE = <<-EOT
Usage: rails COMMAND [ARGS]

The most common rails commands are:
 generate    Generate new code (short-cut alias: "g")
 console     Start the Rails console (short-cut alias: "c")
 server      Start the Rails server (short-cut alias: "s")
 test        Run tests (short-cut alias: "t")
 dbconsole   Start a console for the database specified in config/database.yml
             (short-cut alias: "db")
 new         Create a new Rails application. "rails new my_app" creates a
             new application called MyApp in "./my_app"

In addition to those, there are:
 destroy      Undo code generated with "generate" (short-cut alias: "d")
 plugin new   Generates skeleton for developing a Rails plugin
 runner       Run a piece of code in the application environment (short-cut alias: "r")

All commands can be run with -h (or --help) for more information.
EOT

    def initialize(argv)
      @argv = argv
      @command = Rails::Commands::Command.new(argv)
    end

    def run_command!(command)
      write_error_message(command) unless @command.run(command)
    end

    def help
      write_help_message
    end

    private

      def exit_with_initialization_warning!
        puts "Can't initialize a new Rails application within the directory of another, please change to a non-Rails directory first.\n"
        puts "Type 'rails' for help."
        exit(1)
      end

      def write_help_message
        puts HELP_MESSAGE
      end

      # Output an error message stating that the attempted command is not a valid rails command.
      # Run the attempted command as a rake command with the --dry-run flag. If successful, suggest
      # to the user that they possibly meant to run the given rails command as a rake command.
      # Append the help message.
      #
      #   Example:
      #   $ rails db:migrate
      #   Error: Command 'db:migrate' not recognized
      #   Did you mean: `$ rake db:migrate` ?
      #   (Help message output)
      #
      def write_error_message(command)
        puts "Error: Command '#{command}' not recognized"
        if %x{rake #{command} --dry-run 2>&1 } && $?.success?
          puts "Did you mean: `$ rake #{command}` ?\n\n"
        end
        write_help_message
        exit(1)
      end
  end
end
