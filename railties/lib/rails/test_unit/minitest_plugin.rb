require "rails/test_unit/reporter"

module Minitest
  def self.plugin_rails_options(opts, options)
    opts.separator "Usage: bin/rails test [options] [file or directory]"
    opts.separator "You can run a single test by appending the line number to filename:"
    opts.separator ""
    opts.separator "bin/rails test test/models/user_test.rb:27"

    opts.on("-e", "--environment [ENV]",
            "Run tests in the ENV environment") do |env|
      options[:environment] = env.strip
    end

    opts.on("-b", "--backtrace",
            "Show the complete backtrace") do
      options[:backtrace] = true
    end
  end

  def self.plugin_rails_init(options)
    ENV["RAILS_ENV"] = options[:environment] || "test"

    options[:patterns] = OptionParser.new(options[:args]).order!
    Rails::TestRunner.require_files options[:patterns]

    if !options[:backtrace] || !ENV["BACKTRACE"]
      Minitest.backtrace_filter = Rails.backtrace_cleaner
    end

    self.reporter << Rails::TestUnitReporter.new(options[:io], options)
  end
end

Minitest.extensions << 'rails'
