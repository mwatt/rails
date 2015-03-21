require "minitest"
require "method_source"
require "rake/file_list"
require "rails/test_unit/reporter"
require "rails/test_unit/test_requirer"

module Minitest
  def self.plugin_rails_options(opts, options)
    opts.separator "Usage: bin/rails test [options] [file or directory]"

    opts.on("-e", "--environment [ENV]",
            "Run tests in the ENV environment") do |env|
      options[:environment] = env.strip
    end

    opts.on("-n", "--name [FILENAME:LINE]",
            "Run a single test by appending the line number to filename:\n\n" \
            "bin/rails test test/models/user_test.rb:27") do |name|
      options[:filter] = name
    end

    opts.on("-b", "--backtrace",
            "Show the complete backtrace") do
      options[:backtrace] = true
    end

    ENV["RAILS_ENV"] = options[:environment] || "test"
  end

  def self.plugin_rails_init(options)
    Rails::TestRequirer.require_tests OptionParser.new(options[:args]).order!

    if file_and_line = options[:filter]
      file, line = file_and_line.split(':')

      if file && line
        options[:filter] = FileAndLineFilter.new(self, File.expand_path(file), line.to_i)
      end
    end

    if !options[:backtrace] || !ENV["BACKTRACE"]
      Minitest.backtrace_filter = Rails.backtrace_cleaner
    end

    self.reporter << Rails::TestUnitReporter.new(options[:io], options)
  end

  private
    class FileAndLineFilter < Struct.new(:klass, :file, :line)
      def ===(method)
        if klass.method_defined?(method)
          test_file, test_range = definition_for(klass.instance_method(method))
          test_file == file && test_range.include?(line)
        end
      end

      def definition_for(method)
        file, start_line = method.source_location
        end_line = method.source.count("\n") + start_line - 1

        return file, start_line..end_line
      end
    end
end

Minitest.extensions << 'rails'
