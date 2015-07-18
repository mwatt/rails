require 'active_support/concurrency/share_lock'

module ActiveSupport #:nodoc:
  module Dependencies #:nodoc:
    class Interlock
      def initialize # :nodoc:
        @load_lock = ActiveSupport::Concurrency::ShareLock.new(true)
        @unload_lock = ActiveSupport::Concurrency::ShareLock.new(true)
      end

      def loading
        @unload_lock.sharing do
          @load_lock.exclusive do
            yield
          end
        end
      end

      def unloading
        @unload_lock.exclusive do
          yield
        end
      end

      # Attempt to obtain a "unloading" (exclusive) lock. If possible,
      # execute the supplied block while holding the lock. If there is
      # concurrent activity, return immediately (without executing the
      # block) instead of waiting.
      def attempt_unloading
        @unload_lock.exclusive(true) do
          yield
        end
      end

      def start_running
        @unload_lock.start_sharing
        @load_lock.start_sharing
      end

      def done_running
        @load_lock.stop_sharing
        @unload_lock.stop_sharing
      end

      def running
        @unload_lock.sharing do
          @load_lock.sharing do
            yield
          end
        end
      end
    end
  end
end
