module ActiveSupport
  module Testing
    module MethodCallAssertions # :nodoc:
      def assert_called(object, method_name, message = nil, times: 1)
        times_called = 0

        object.stub(method_name, -> { times_called += 1 }) { yield }

        error = "Expected #{method_name} to be called #{times} times, " \
          "but was called #{times_called} times"
        error = "#{message}.\n#{error}" if message
        assert_equal times, times_called, error
      end

      def assert_not_called(object, method_name, message = nil, &block)
        assert_called(object, method_name, message, times: 0, &block)
      end
    end
  end
end
