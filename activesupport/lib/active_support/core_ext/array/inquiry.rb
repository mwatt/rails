class Array
  # Wraps the array in an +ArrayInquirer+ object, which gives a friendlier way
  # to check its string-like contents.
  #
  #   pets = [:cat, :dog]
  #   pets.cat?    # => true
  #   pets.ferret? # => false
  #   pets.any?(:cat, :ferret) # => true
  def inquiry
    ActiveSupport::ArrayInquirer.new(self)
  end
end
