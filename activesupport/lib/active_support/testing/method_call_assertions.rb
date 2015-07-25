module ActiveSupport
  module Testing
    module MethodCallAssertions # :nodoc:
      private
        def assert_called(object, method_name, message = nil, times: 1)
          times_called = 0

          object.stub(method_name, -> { times_called += 1 }) { yield }

          assert_equal times, times_called, error_message(method_name, times, times_called, message)
        end

        def assert_called_with(object, method_name, args = [], returns: nil)
          mock = Minitest::Mock.new

          if args.all? { |arg| arg.is_a?(Array) }
            args.each { |arg| mock.expect(:call, returns, arg) }
          else
            mock.expect(:call, returns, args)
          end

          object.stub(method_name, mock) { yield }

          mock.verify
        end

        def assert_not_called(object, method_name, message = nil, &block)
          assert_called(object, method_name, message, times: 0, &block)
        end

        def assert_any_instance_called(klass, method_name, times: 1, returns: nil)
          times_called = 0

          klass.class_eval { define_method(method_name) { |*args| times_called += 1; returns } }
          yield

          assert_equal times, times_called, error_message(method_name, times, times_called)
        end

        def assert_any_instance_not_called(klass, method_name, &block)
          assert_any_instance_called(klass, method_name, times: 0, &block)
        end

        def error_message(method_name, times, times_called, message=nil)
          error = "Expected #{method_name} to be called #{times} times, " \
            "but was called #{times_called} times"
          error = "#{message}.\n#{error}" if message
          error
        end
    end
  end
end
