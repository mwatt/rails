require 'abstract_unit'


class MultibyteUnicodeDatabaseTest < ActiveSupport::TestCase

  include ActiveSupport::Multibyte::Unicode

  def setup
    @ucd = UnicodeDatabase.new
  end

  UnicodeDatabase::ATTRIBUTES.each do |attribute|
    define_method "test_lazy_loading_on_attribute_access_of_#{attribute}" do
      mock = MiniTest::Mock.new
      mock.expect(:call, nil, [])
      @ucd.stub(:load, mock) do
        @ucd.send(attribute)
      end
      mock.verify
    end
  end

  def test_load
    @ucd.load
    UnicodeDatabase::ATTRIBUTES.each do |attribute|
      assert @ucd.send(attribute).length > 1
    end
  end
end
