require 'rails/test_unit/minitest_plugin'
require 'rails/commands/command'

module Rails
  module Commands
    class Test < Command
      options_for :test do |opts, _|
        opts.banner = 'Run test suite.'
      end

      options_for :test_db do |opts, _|
        opts.banner = ''
      end

      rake_delegate 'test', 'test:db'
    end
  end
end
