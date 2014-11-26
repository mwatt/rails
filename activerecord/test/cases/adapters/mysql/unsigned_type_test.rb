require "cases/helper"
require "support/schema_dumping_helper"

class MysqlUnsignedTypeTest < ActiveRecord::MysqlTestCase
  include SchemaDumpingHelper
  self.use_transactional_tests = false

  class UnsignedType < ActiveRecord::Base
  end

  setup do
    @connection = ActiveRecord::Base.connection
    @connection.create_table("unsigned_types", force: true) do |t|
      t.integer :unsigned_integer, unsigned: true
      t.bigint  :unsigned_bigint,  unsigned: true
      t.float   :unsigned_float,   unsigned: true
      t.decimal :unsigned_decimal, unsigned: true, precision: 10, scale: 2
    end
  end

  teardown do
    @connection.drop_table "unsigned_types", if_exists: true
  end

  test "unsigned int max value is in range" do
    assert expected = UnsignedType.create(unsigned_integer: 4294967295)
    assert_equal expected, UnsignedType.find_by(unsigned_integer: 4294967295)
  end

  test "minus value is out of range" do
    assert_raise(RangeError) do
      UnsignedType.create(unsigned_integer: -10)
    end
    assert_raise(RangeError) do
      UnsignedType.create(unsigned_bigint: -10)
    end
    assert_raise(ActiveRecord::StatementInvalid) do
      UnsignedType.create(unsigned_float: -10.0)
    end
    assert_raise(ActiveRecord::StatementInvalid) do
      UnsignedType.create(unsigned_decimal: -10.0)
    end
  end

  test "schema dump includes unsigned option" do
    schema = dump_table_schema "unsigned_types"
    assert_match %r{t.integer\s+"unsigned_integer",\s+limit: 4,\s+unsigned: true$}, schema
    assert_match %r{t.integer\s+"unsigned_bigint",\s+limit: 8,\s+unsigned: true$}, schema
    assert_match %r{t.float\s+"unsigned_float",\s+limit: 24,\s+unsigned: true$}, schema
    assert_match %r{t.decimal\s+"unsigned_decimal",\s+precision: 10,\s+scale: 2,\s+unsigned: true$}, schema
  end
end
