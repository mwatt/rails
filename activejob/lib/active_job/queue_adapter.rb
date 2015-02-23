require 'active_job/queue_adapters/inline_adapter'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'

module ActiveJob
  # The <tt>ActiveJob::QueueAdapter</tt> module is used to load the
  # correct adapter. The default queue adapter is the :inline queue.
  module QueueAdapter #:nodoc:
    # We can't use ActiveSupport::Concern here because we need to `prepend`
    # ClassMethods rather than `extend`ing it.
    def self.included(klass)
      klass.class_attribute :queue_adapter, instance_accessor: false, instance_predicate: false
      klass.singleton_class.prepend(ClassMethods)
      klass.queue_adapter = :inline
    end

    # Includes the setter method for changing the active queue adapter.
    module ClassMethods
      # Specify the backend queue provider. The default queue adapter
      # is the :inline queue. See QueueAdapters for more
      # information.
      def queue_adapter=(name_or_adapter)
        super(interpret_adapter(name_or_adapter))
      end

      private
        def interpret_adapter(name_or_adapter)
          case name_or_adapter
          when Symbol, String
            load_adapter(name_or_adapter)
          else
            name_or_adapter if name_or_adapter.respond_to?(:enqueue)
          end
        end

        def load_adapter(name)
          "ActiveJob::QueueAdapters::#{name.to_s.camelize}Adapter".constantize
        end
    end
  end
end
