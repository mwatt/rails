require 'rails/commands/core'
require 'rails/commands/test'
require 'rails/commands/assets'
require 'rails/commands/tmp'

module Rails
  module Commands
    # This class delegates each rails command to the corresponding class
    class Warden
      attr_accessor :command, :argv

      def initialize(command, argv)
        @command = command
        @argv = argv
      end

      def run!
        method_name = command.gsub(/:/, "_")

        if Rails::Commands::Core::COMMAND_WHITELIST.include?(command)
          core_commands.send(method_name)
        elsif Rails::Commands::Test::COMMAND_WHITELIST.include?(command)
          test_commands.send(method_name)
        elsif Rails::Commands::Assets::COMMAND_WHITELIST.include?(command)
          asset_commands.send(method_name)     
        elsif Rails::Commands::Tmp::COMMAND_WHITELIST.include?(command)
          tmp_commands.send(method_name)
        else
          return false
        end

        true
      end

      protected

        def core_commands
          Rails::Commands::Core.new(argv)
        end

        def test_commands
          Rails::Commands::Test.new(argv)
        end

        def asset_commands
          Rails::Commands::Assets.new(argv)
        end

        def tmp_commands
          Rails::Commands::Tmp.new(argv)
        end
    end
  end
end
