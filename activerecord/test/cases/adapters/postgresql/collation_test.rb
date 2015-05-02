require "cases/helper"
require 'support/schema_dumping_helper'

class PostgresqlCollationTest < ActiveRecord::TestCase
  include SchemaDumpingHelper

  def setup
    @connection = ActiveRecord::Base.connection
    @connection.create_table :postgresql_collations, force: true do |t|
      t.string :string_en, collation: 'en_US.UTF-8'
      t.text :text_ja, collation: 'ja_JP.UTF-8'
    end
  end

  def teardown
    @connection.drop_table :postgresql_collations, if_exists: true
  end

  test "string column with collation" do
    column = @connection.columns(:postgresql_collations).find { |c| c.name == 'string_en' }
    assert_equal :string, column.type
    assert_equal 'en_US.UTF-8', column.collation
  end

  test "text column with collation" do
    column = @connection.columns(:postgresql_collations).find { |c| c.name == 'text_ja' }
    assert_equal :text, column.type
    assert_equal 'ja_JP.UTF-8', column.collation
  end

  test "add column with collation" do
    @connection.add_column :postgresql_collations, :title, :string, collation: 'en_AU.UTF-8'

    column = @connection.columns(:postgresql_collations).find { |c| c.name == 'title' }
    assert_equal :string, column.type
    assert_equal 'en_AU.UTF-8', column.collation
  end

  test "change column with collation" do
    @connection.add_column :postgresql_collations, :description, :string
    @connection.change_column :postgresql_collations, :description, :text, collation: 'en_CA.UTF-8'

    column = @connection.columns(:postgresql_collations).find { |c| c.name == 'description' }
    assert_equal :text, column.type
    assert_equal 'en_CA.UTF-8', column.collation
  end

  test "schema dump includes collation" do
    output = dump_table_schema("postgresql_collations")
    assert_match %r{t.string\s+"string_en",\s+collation: "en_US.UTF-8"$}, output
    assert_match %r{t.text\s+"text_ja",\s+collation: "ja_JP.UTF-8"$}, output
  end
end
