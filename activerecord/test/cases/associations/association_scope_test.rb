require 'cases/helper'
require 'models/post'
require 'models/author'
require "models/interior_designer"
require "models/chef"

module ActiveRecord
  module Associations
    class AssociationScopeTest < ActiveRecord::TestCase
      test 'does not duplicate conditions' do
        scope = AssociationScope.scope(Author.new.association(:welcome_posts),
                                        Author.connection)
        wheres = scope.where_values.map(&:right)
        binds = scope.bind_values.map(&:last)
        wheres = scope.where_values.map(&:right).reject { |node|
          Arel::Nodes::BindParam === node
        }
        assert_equal wheres.uniq, wheres
        assert_equal binds.uniq, binds
      end

      test 'uses STI name for polymorphic associations' do
        scope = AssociationScope.scope(
          InteriorDesigner.new.association(:chef),
          InteriorDesigner.connection
        )
        sql = scope.to_sql

        assert_no_match(/'InteriorDesigner'/, sql)
        assert_match(/'InteriorDecorator'/, sql)
      end
    end
  end
end
