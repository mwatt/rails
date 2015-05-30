require 'isolation/abstract_unit'
require 'rack/test'

module ApplicationTests
  class RoutingTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::Isolation
    include Rack::Test::Methods

    def setup
      make_basic_app do |app|
        app.config.consider_all_requests_local = true
      end
    end

    def teardown
      teardown_app
    end

    test "per request fragment caching" do
      app_file 'app/models/customer.rb', <<-RUBY
        class Customer < Struct.new(:name, :id)
          extend ActiveModel::Naming
          include ActiveModel::Conversion
        end
      RUBY

      app_file 'config/routes.rb', <<-RUBY
        Rails.application.routes.draw do
          resources :customers
        end
      RUBY

      app_file 'app/controllers/customers_controller.rb', <<-RUBY
        class CustomersController < ApplicationController
          def show
            render Customer.new('david', params[:id])
          end
        end
      RUBY

      app_file 'app/views/customers/_customer.html.erb', <<-RUBY
        <%= cache customer do %>
          <%= customer.name %>
        <% end %>
      RUBY

      get '/customers/1'
      assert_equal 200, last_response.status

      write_not_called = true

      ActionView::Base.per_request_fragment_cache.stub(:fetch, -> { write_not_called = false }) do
        get '/customers/1'
      end

      assert write_not_called
    end
  end
end
