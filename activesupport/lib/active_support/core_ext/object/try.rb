require 'delegate'

class Tries #:nodoc:
  def self.try(o, *a, &b)
    try!(o, *a, &b) if a.empty? || o.respond_to?(a.first)
  end

  def self.try!(o, *a, &b)
    if a.empty? && block_given?
      if b.arity.zero?
        o.instance_eval(&b)
      else
        yield o
      end
    else
      o.public_send(*a, &b)
    end
  end
end

class Object
  # Invokes the public method whose name goes as first argument just like
  # +public_send+ does, except that if the receiver does not respond to it the
  # call returns +nil+ rather than raising an exception.
  #
  # This method is defined to be able to write
  #
  #   @person.try(:name)
  #
  # instead of
  #
  #   @person.name if @person
  #
  # +try+ calls can be chained:
  #
  #   @person.try(:spouse).try(:name)
  #
  # instead of
  #
  #   @person.spouse.name if @person && @person.spouse
  #
  # +try+ will also return +nil+ if the receiver does not respond to the method:
  #
  #   @person.try(:non_existing_method) # => nil
  #
  # instead of
  #
  #   @person.non_existing_method if @person.respond_to?(:non_existing_method) # => nil
  #
  # +try+ returns +nil+ when called on +nil+ regardless of whether it responds
  # to the method:
  #
  #   nil.try(:to_i) # => nil, rather than 0
  #
  # Arguments and blocks are forwarded to the method if invoked:
  #
  #   @posts.try(:each_slice, 2) do |a, b|
  #     ...
  #   end
  #
  # The number of arguments in the signature must match. If the object responds
  # to the method the call is attempted and +ArgumentError+ is still raised
  # in case of argument mismatch.
  #
  # If +try+ is called without arguments it yields the receiver to a given
  # block unless it is +nil+:
  #
  #   @person.try do |p|
  #     ...
  #   end
  #
  # You can also call try with a block without accepting an argument, and the block
  # will be instance_eval'ed instead:
  #
  #   @person.try { upcase.truncate(50) }
  #
  # Please also note that +try+ is defined on +Object+. Therefore, it won't work
  # with instances of classes that do not have +Object+ among their ancestors,
  # like direct subclasses of +BasicObject+.
  def try(*a, &b)
    Tries.try(self, *a, &b)
  end

  # Same as #try, but raises a NoMethodError exception if the receiver is
  # not +nil+ and does not implement the tried method.
  #
  #   "a".try!(:upcase) # => "A"
  #   nil.try!(:upcase) # => nil
  #   123.try!(:upcase) # => NoMethodError: undefined method `upcase' for 123:Fixnum
  def try!(*a, &b)
    Tries.try!(self, *a, &b)
  end
end

class NilClass
  # Calling +try+ on +nil+ always returns +nil+.
  # It becomes especially helpful when navigating through associations that may return +nil+.
  #
  #   nil.try(:name) # => nil
  #
  # Without +try+
  #   @person && @person.children.any? && @person.children.first.name
  #
  # With +try+
  #   @person.try(:children).try(:first).try(:name)
  def try(*args)
    nil
  end

  # Calling +try!+ on +nil+ always returns +nil+.
  #
  #   nil.try!(:name) # => nil
  def try!(*args)
    nil
  end
end

class Delegator
  # See Object#try
  def try(*a, &b)
    Tries.try(self, *a, &b)
  end

  # See Object#try!
  def try!(*a, &b)
    Tries.try!(self, *a, &b)
  end
end
