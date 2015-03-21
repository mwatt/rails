require 'method_source'
require 'rake/file_list'
require 'rails/test_unit/minitest_plugin'

module Rails
  class TestRunner
    class << self
      def run(patterns = nil)
        require_files patterns if patterns

        Minitest.run(ARGV)
      end

      def require_files(patterns)
        patterns = expand_patterns(patterns)

        Rake::FileList[patterns.compact.presence || 'test/**/*_test.rb'].to_a.each do |file|
          require File.expand_path(file)
        end
      end

      private
        def expand_patterns(patterns)
          patterns.map do |arg|
            arg = arg.gsub(/:(\d+)?$/, '')
            if Dir.exist?(arg)
              "#{arg}/**/*_test.rb"
            elsif File.file?(arg)
              arg
            end
          end
        end
    end
  end
end
