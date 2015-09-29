module Rails
  module Commands
    class Command
      attr_reader :argv

      def initialize(argv)
        @argv = argv
      end

      def run(task_name)
        command_name = Command.name_for(task_name)

        if command_instance = command_instance_for(command_name)
          command_instance.public_send(command_name)
          true
        else
          # Print help or some other documentation

          return false
        end
      end

      def tasks
        public_instance_methods.map { |method| method.gsub('_', ':') }
      end

      def self.rake_delegate(*task_names)
        task_names.each do |task_name|
          define_method(name_for(task_name)) do
            Rake::Task[task_name].invoke
          end
        end
      end

      def self.name_for(task_name)
        task_name.gsub(':', '_')
      end

      private
        @@commands = []

        def self.inherited(command)
          @@commands << command
        end

        def command_instance_for(command_name)
          klass = @@commands.find do |command|
            command_instance_methods = command.public_instance_methods
            command_instance_methods.include?(command_name.to_sym)
          end

          klass.new(@argv)
        end
    end
  end
end
