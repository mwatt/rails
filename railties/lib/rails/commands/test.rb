require "rails/test_unit/minitest_plugin"

$: << File.expand_path("../../test", APP_PATH)

Minitest.run(ARGV)
