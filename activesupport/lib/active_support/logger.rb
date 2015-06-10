require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/logger_silence'
require 'logger'

module ActiveSupport
  class Logger < ::Logger
    include LoggerSilence

    # Broadcasts logs to multiple loggers.
    def self.broadcast(logger) # :nodoc:
      Module.new do
        define_method(:add) do |*args, &block|
          logger.add(*args, &block)
          super(*args, &block)
        end

        define_method(:<<) do |x|
          logger << x
          super(x)
        end

        define_method(:close) do
          logger.close
          super()
        end

        define_method(:progname=) do |name|
          logger.progname = name
          super(name)
        end

        define_method(:formatter=) do |formatter|
          logger.formatter = formatter
          super(formatter)
        end

        define_method(:level=) do |level|
          logger.level = level
          super(level)
        end
      end
    end

    def initialize(*args)
      super
      @formatter   = SimpleFormatter.new
    end

    def level
      # The default log level is set the first time the level is set for this object,
      # which means that if our current thread doesn't have a local level set, then
      # we attempt to use the main thread's default level, falling back to the class
      # default otherwise.
      Thread.current[local_level_key] || Thread.main[default_level_key] || super
    end

    def level=(level)
      # Set system-wide default logger level the first time we set our level
      # Note: this assumes that the first level we set is the level that what
      # we expect to use as the default for the life of this object.
      Thread.main[default_level_key] ||= level
      Thread.current[local_level_key] = level
    end

    def add(severity, message = nil, progname = nil, &block)
      return true if @logdev.nil? || (severity || UNKNOWN) < level
      super
    end

    Logger::Severity.constants.each do |severity|
      class_eval(<<-EOT, __FILE__, __LINE__ + 1)
        def #{severity.downcase}?                # def debug?
          Logger::#{severity} >= level           #   DEBUG >= level
        end                                      # end
      EOT
    end

    # Simple formatter which only displays the message.
    class SimpleFormatter < ::Logger::Formatter
      # This method is invoked when a log event occurs
      def call(severity, timestamp, progname, msg)
        "#{String === msg ? msg : msg.inspect}\n"
      end
    end

    private

      def default_level_key
        @default_key ||= "#{self.object_id}_default_logger_level"
      end

      def local_level_key
        @level_key ||= "#{self.object_id}_local_logger_level"
      end
  end
end
