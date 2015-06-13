# The class Region (without namespace) shouldn't exist
# in order to the test test_type_mismatch_with_namespaced_class
# be valid
class Admin::Region < ActiveRecord::Base
  has_many :users
end
