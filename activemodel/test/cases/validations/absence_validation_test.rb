require 'cases/helper'
require 'models/topic'
require 'models/custom_reader'

class AbsenceValidationTest < ActiveModel::TestCase
  teardown do
    Topic.clear_validators!
    CustomReader.clear_validators!
  end

  def test_validates_absence_of
    Topic.validates_absence_of(:title, :content)
    t = Topic.new
    t.title = "foo"
    t.content = "bar"
    assert t.invalid?
    assert_equal ["must be blank"], t.errors[:title]
    assert_equal ["must be blank"], t.errors[:content]
    t.title = ""
    t.content  = "something"
    assert t.invalid?
    assert_equal ["must be blank"], t.errors[:content]
    assert_equal [], t.errors[:title]
    t.content = ""
    assert t.valid?
  end

  def test_validates_absence_of_with_array_arguments
    Topic.validates_absence_of %w(title content)
    t = Topic.new
    t.title = "foo"
    t.content = "bar"
    assert t.invalid?
    assert_equal ["must be blank"], t.errors[:title]
    assert_equal ["must be blank"], t.errors[:content]
  end

  def test_validates_absence_of_with_custom_error_using_quotes
    Topic.validates_absence_of :title, message: "This string contains 'single' and \"double\" quotes"
    t = Topic.new
    t.title = "good"
    assert t.invalid?
    assert_equal "This string contains 'single' and \"double\" quotes", t.errors[:title].last
  end

  def test_validates_absence_of_for_ruby_class
    Topic.validates_absence_of :title
    t = Topic.new
    t.title = "good"
    assert t.invalid?
    assert_equal ["must be blank"], t.errors[:title]
    t.title = nil
    assert t.valid?
  end

  def test_validates_absence_of_for_ruby_class_with_custom_reader
    CustomReader.validates_absence_of :title
    t = CustomReader.new
    t[:title] = "excellent"
    assert t.invalid?
    assert_equal ["must be blank"], t.errors[:title]
    t[:title] = ""
    assert t.valid?
  end
end
