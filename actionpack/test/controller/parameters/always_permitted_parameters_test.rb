require 'abstract_unit'
require 'action_controller/metal/strong_parameters'

class AlwaysPermittedParametersTest < ActiveSupport::TestCase
  def setup
    ActionController::Parameters.action_on_unpermitted_parameters = :raise
    ActionController::Parameters.always_permitted_parameters = %w( controller action format )
  end

  def teardown
    ActionController::Parameters.action_on_unpermitted_parameters = false
    ActionController::Parameters.always_permitted_parameters = %w( controller action )
  end

  test "shows deprecations warning on NEVER_UNPERMITTED_PARAMS" do
    assert_deprecated do
      ActionController::Parameters::NEVER_UNPERMITTED_PARAMS
    end
  end

  test "respects constant resolution chain on const_missing" do
    module ParentModule
      def self.const_missing(const_name)
        "parent"
      end

      class MyParameters < ActionController::Parameters
      end
    end

    assert_equal "parent", ParentModule::MyParameters::NON_EXISTING_CONSTANT
  end

  test "permits parameters that are whitelisted" do
    params = ActionController::Parameters.new({
      book: { pages: 65 },
      format: "json"
    })
    permitted = params.permit book: [:pages]
    assert permitted.permitted?
  end
end
