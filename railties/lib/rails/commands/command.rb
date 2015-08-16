require 'byebug'

module Rails
  module Commands
    class Command
      attr_reader :argv

      def initialize(argv)
        @argv = argv
      end

      def run(task_name)
        command_name = command_name_for(task_name)

        if command = command_instance_for(command_name)
          command.public_send(command_name)
          true
        else
          # Print help or some other documentation

          return false
        end
      end

      def tasks
        public_instance_methods.map { |method| method.gsub('_', ':') }
      end

      private
        @@command_wrappers = []

        def self.inherited(command)
          @@command_wrappers << command
        end

        def command_instance_for(task_name)
          command_name = command_name_for(task_name)
          klass = @@command_wrappers.find do |command| 
            command.method_defined?(command_name)
          end
          klass.new(@argv)
        end

        def command_name_for(task_name)
          task_name.gsub(':', '_')
        end
    end
  end
end
