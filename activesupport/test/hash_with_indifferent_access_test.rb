require 'abstract_unit'
require 'active_support/hash_with_indifferent_access'

class HashWithIndifferentAccessTest < ActiveSupport::TestCase
  def test_reverse_merge
    hash = HashWithIndifferentAccess.new key: :old_value
    hash.reverse_merge! key: :new_value
    assert_equal :old_value, hash[:key]
  end

  def test_dup_with_default_proc
    hash = HashWithIndifferentAccess.new
    hash.default_proc = proc { |h, v| raise "walrus" }
    assert_nothing_raised { hash.dup }
  end

  def test_dup_with_default_proc_sets_proc
    hash = HashWithIndifferentAccess.new
    hash.default_proc = proc { |h, k| k + 1 }
    new_hash = hash.dup

    assert_equal 3, new_hash[2]

    new_hash.default = 2
    assert_equal 2, new_hash[:non_existant]
  end
end
