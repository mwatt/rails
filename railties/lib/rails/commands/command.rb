module Rails
  module Commands
    class Command
      attr_reader :argv

      def initialize(argv)
        @argv = argv
      end

      def run(task_name)
        command_name = Command.name_for(task_name)

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
        @@command_wrappers = []

        def self.inherited(command)
          @@command_wrappers << command
        end

        def command_instance_for(command_name)
          klass = @@command_wrappers.find do |command_wrapper|
            command_instance_methods = command_wrapper.public_instance_methods
            command_instance_methods.include?(command_name.to_sym)
          end

          klass.new(@argv)
        end
    end
  end
end
