ORIG_ARGV = ARGV.dup

begin
  old, $VERBOSE = $VERBOSE, nil
  require File.expand_path('../../../load_paths', __FILE__)
ensure
  $VERBOSE = old
end

require 'active_support/core_ext/kernel/reporting'

silence_warnings do
  Encoding.default_internal = "UTF-8"
  Encoding.default_external = "UTF-8"
end

require 'active_support/testing/autorun'

ENV['NO_RELOAD'] = '1'
require 'active_support'

Thread.abort_on_exception = true

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true

# Disable available locale checks to avoid warnings running the test suite.
I18n.enforce_available_locales = false

# Skips the current run on Rubinius using Minitest::Assertions#skip
def rubinius_skip(message = '')
  skip message if RUBY_ENGINE == 'rbx'
end

# Skips the current run on JRuby using Minitest::Assertions#skip
def jruby_skip(message = '')
  skip message if defined?(JRUBY_VERSION)
end

require 'minitest/mock'
require 'mocha/setup' # FIXME: stop using mocha

class ActiveSupport::TestCase
  def assert_called(object, method_name, message = nil, times: 1) # :nodoc:
    times_called = 0

    object.stub(method_name, -> { times_called += 1 }) { yield }

    error = "Expected #{method_name} to be called #{times} times, " \
      "but was called #{times_called} times"
    error = "#{message}.\n#{error}" if message
    assert_equal times, times_called, error
  end

  def assert_called_with(object, method_name, args = [], returns: nil) # :nodoc:
    mock = Minitest::Mock.new
    mock.expect(:call, returns, args)

    object.stub(method_name, mock) { yield }

    mock.verify
  end

  def assert_not_called(object, method_name, message = nil, &block) # :nodoc:
    assert_called(object, method_name, message, times: 0, &block)
  end
end
