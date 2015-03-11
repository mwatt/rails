require 'active_job/queue_adapters/inline_adapter'
require 'active_support/core_ext/string/inflections'

module ActiveJob
  # The <tt>ActiveJob::QueueAdapter</tt> module is used to load the
  # correct adapter. The default queue adapter is the :inline queue.
  module QueueAdapter #:nodoc:
    extend ActiveSupport::Concern

    # Includes the setter method for changing the active queue adapter.
    module ClassMethods
      mattr_reader(:queue_adapter) { ActiveJob::QueueAdapters::InlineAdapter }

      # Specify the backend queue provider. The default queue adapter
      # is the :inline queue. See QueueAdapters for more
      # information.
      def queue_adapter=(name_or_adapter_or_class)
        @@queue_adapter = \
          case name_or_adapter_or_class
          when Symbol, String
            load_adapter(name_or_adapter_or_class)
          else
            if name_or_adapter_or_class.respond_to?(:enqueue)
              name_or_adapter_or_class
            else
              name_or_adapter_or_class.new
            end
          end
      end

      private
        def load_adapter(name)
          "ActiveJob::QueueAdapters::#{name.to_s.camelize}Adapter".constantize.new
        end
    end
  end
end
