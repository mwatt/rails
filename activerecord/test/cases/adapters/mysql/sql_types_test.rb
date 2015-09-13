require "cases/helper"

class MysqlSqlTypesTest < ActiveRecord::MysqlTestCase
  def test_binary_types
    assert_equal 'varbinary(64)', type_to_sql(:binary, 64)
    assert_equal 'varbinary(4095)', type_to_sql(:binary, 4095)
    assert_equal 'blob', type_to_sql(:binary, 4096)
    assert_equal 'blob', type_to_sql(:binary)
    assert_equal 'mediumblob', type_to_sql(:binary, 16777215)
    assert_equal 'longblob', type_to_sql(:binary, 2147483647)
  end

  def test_text_types
    assert_equal 'tinytext', type_to_sql(:text, 255)
    assert_equal 'text', type_to_sql(:text, 65535)
    assert_equal 'text', type_to_sql(:text)
    assert_equal 'mediumtext', type_to_sql(:text, 16777215)
    assert_equal 'longtext', type_to_sql(:text, 2147483647)
  end

  def type_to_sql(*args)
    ActiveRecord::Base.connection.type_to_sql(*args)
  end
end
