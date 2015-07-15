require 'isolation/abstract_unit'

class WildcardDependenciesTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  setup do
    build_app
    require "#{app_path}/config/environment"
  end

  teardown :teardown_app

  test "dependency tracker view_paths are set in initializer" do
    assert_equal ActionController::Base.view_paths, ActionView::DependencyTracker.view_paths
  end
end
