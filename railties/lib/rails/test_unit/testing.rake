gem 'minitest'
require 'minitest'
require 'rails/test_unit/minitest_plugin'

task default: :test

desc "Runs all tests in test folder"
task :test do
  $: << "test"
  Minitest.test_patterns = ["test"]
  Minitest.run
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
      $: << "test"
      Minitest.test_patterns = ["test/#{name}"]
      Minitest.run
    end
  end

  task :generators => "test:prepare" do
    $: << "test"
    Minitest.test_patterns = ["test/lib/generators"]
    Minitest.run
  end

  task :units => "test:prepare" do
    $: << "test"
    Minitest.test_patterns = ["test/models", "test/helpers", "test/unit"]
    Minitest.run
  end

  task :functionals => "test:prepare" do
    $: << "test"
    Minitest.test_patterns = ["test/controllers", "test/mailers", "test/functional"]
    Minitest.run
  end
end
