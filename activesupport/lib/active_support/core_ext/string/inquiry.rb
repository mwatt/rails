require 'active_support/string_inquirer'

class String
  # Wraps the current string in the <tt>ActiveSupport::StringInquirer</tt> class,
  # which gives you a prettier way to test for equality.
  #
  #   env = 'production'.inquiry
  #   env.production?  # => true
  #   env.development? # => false
  def inquiry(*valid_values)
    ActiveSupport::StringInquirer.new(self, valid_values.flatten)
  end
end
