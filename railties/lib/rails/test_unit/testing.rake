require "rails/test_unit/runner"

task default: :test

desc "Runs all tests in test folder"
task :test do
  args = ARGV[0] == "test" ? ARGV[1..-1] : []
  run_test_task(args)
end

namespace :test do
  task :prepare do
    # Placeholder task for other Railtie and plugins to enhance.
    # If used with Active Record, this task runs before the database schema is synchronized.
  end

  task :run => %w[test]

  desc "Run tests quickly, but also reset db"
  task :db => %w[db:test:prepare test]

  ["models", "helpers", "controllers", "mailers", "integration", "jobs"].each do |name|
    task name => "test:prepare" do
      run_test_task(["test/#{name}"])
    end
  end

  task :generators => "test:prepare" do
    run_test_task(["test/lib/generators"])
  end

  task :units => "test:prepare" do
    run_test_task(["test/models", "test/helpers", "test/unit"])
  end

  task :functionals => "test:prepare" do
    run_test_task(["test/controllers", "test/mailers", "test/functional"])
  end
end

def run_test_task(args)
  $: << 'test'
  ENV['RUN_TESTS_AT_EXIT'] ||= 'false'
  Rails::TestRunner.run(args)
end
