require 'rails/test_unit/minitest_plugin'
require 'rails/commands/command'

module Rails
  module Commands
    class Test < Command
      rake_delegate 'test', 'test:db'

      set_banner :test, 'Run test suite.'
      set_banner :test_db, ''
    end
  end
end
