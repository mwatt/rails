require 'cases/helper'
require 'support/connection_helper'

class PostgreSQLReferentialIntegrityTest < ActiveRecord::PostgreSQLTestCase
  self.use_transactional_tests = false

  include ConnectionHelper

  IS_REFERENTIAL_INTEGRITY_SQL = lambda do |sql|
    sql.match(/SET CONSTRAINTS ALL DEFERRED/)
  end

  module ProgrammerMistake
    def execute(sql)
      if IS_REFERENTIAL_INTEGRITY_SQL.call(sql)
        raise ArgumentError, 'something is not right.'
      else
        super
      end
    end
  end

  def setup
    @connection = ActiveRecord::Base.connection
  end

  def teardown
    reset_connection
  end

  def test_errors_bubble_up
    @connection.extend ProgrammerMistake

    assert_raises ArgumentError do
      @connection.disable_referential_integrity {}
    end
  end
end
