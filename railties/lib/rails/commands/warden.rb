require 'rails/commands/assets'
require 'rails/commands/core'
require 'rails/commands/dev_cache'
require 'rails/commands/test'
require 'rails/commands/tmp'
require 'byebug'

module Rails
  module Commands
    # This class delegates each rails command to the corresponding class
    class Warden
      attr_accessor :command, :argv

      COMMAND_MAP = {
        core: Rails::Commands::Core::COMMAND_WHITELIST,
        test: Rails::Commands::Test::COMMAND_WHITELIST,
        assets: Rails::Commands::Assets::COMMAND_WHITELIST,
        tmp: Rails::Commands::Tmp::COMMAND_WHITELIST,
        dev_cache: Rails::Commands::Tmp::COMMAND_WHITELIST
      }

      def initialize(command, argv)
        @command = command
        @argv = argv
      end

      def run!
        unless command_class.send(method_name)
          return false
        end

        true
      end

      protected

        def method_name
          command.gsub(/:/, "_")
        end

        def command_class
          key = COMMAND_MAP.select { |key, hash| hash.include?(@command) }
            .keys.first

          send("#{key.to_s}_commands")
        end

        def assets_commands
          Rails::Commands::Assets.new(argv)
        end

        def core_commands
          Rails::Commands::Core.new(argv)
        end

        def dev_cache_commands
          Rails::Commands::DevCache.new(argv)
        end

        def test_commands
          Rails::Commands::Test.new(argv)
        end

        def tmp_commands
          Rails::Commands::Tmp.new(argv)
        end
    end
  end
end
