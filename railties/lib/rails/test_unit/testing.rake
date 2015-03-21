require 'rails/test_unit/test_requirer'

task default: :test

desc "Runs all tests in test folder"
task :test do
  $: << "test"
  Rails::TestRequirer.require_files(['test'])
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
      Rails::TestRequirer.require_files(["test/#{name}"])
    end
  end

  task :generators => "test:prepare" do
    $: << "test"
    Rails::TestRequirer.require_files(["test/lib/generators"])
  end

  task :units => "test:prepare" do
    $: << "test"
    Rails::TestRequirer.require_files(["test/models", "test/helpers", "test/unit"])
  end

  task :functionals => "test:prepare" do
    $: << "test"
    Rails::TestRequirer.require_files(["test/controllers", "test/mailers", "test/functional"])
  end
end
