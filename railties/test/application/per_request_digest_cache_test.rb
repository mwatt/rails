require 'isolation/abstract_unit'
require 'rack/test'
require 'minitest/mock'

require 'action_view'
require 'action_view/base'

require 'active_support/testing/method_call_assertions'

class PerRequestDigestCacheTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation
  include ActiveSupport::Testing::MethodCallAssertions
  include Rack::Test::Methods

  setup do
    build_app
    add_to_config <<-RUBY
      config.consider_all_requests_local = true
      config.action_controller.perform_caching = true
    RUBY

    app_file 'app/models/customer.rb', <<-RUBY
      class Customer < Struct.new(:name, :id)
        extend ActiveModel::Naming
        include ActiveModel::Conversion
      end
    RUBY

    app_file 'config/routes.rb', <<-RUBY
      Rails.application.routes.draw do
        resources :customers, only: :index
      end
    RUBY

    app_file 'app/controllers/customers_controller.rb', <<-RUBY
      class CustomersController < ApplicationController
        def index
          render [ Customer.new('david', 1), Customer.new('dingus', 2) ]
        end
      end
    RUBY

    app_file 'app/views/customers/_customer.html.erb', <<-RUBY
      <% cache customer do %>
        <%= customer.name %>
      <% end %>
    RUBY

    require "#{app_path}/config/environment"
  end

  teardown :teardown_app

  test "digests are reused when rendering the same template twice" do
    get '/customers'
    assert_equal 200, last_response.status

    assert_equal [ '8ba099b7749542fe765ff34a6824d548' ], ActionView::Base.digest_cache.values
    assert_equal %w(david dingus), last_response.body.split.map(&:strip)
  end

  test "template digests are cleared before a request" do
    assert_called(ActionView::Base.digest_cache, :clear) do
      get '/customers'
      assert_equal 200, last_response.status
    end
  end
end
