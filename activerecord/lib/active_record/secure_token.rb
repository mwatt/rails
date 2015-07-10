module ActiveRecord
  module SecureToken
    extend ActiveSupport::Concern

    module ClassMethods
      # Example using has_secure_token
      #
      #   # Schema: User(token:string, auth_token:string)
      #   class User < ActiveRecord::Base
      #     has_secure_token
      #     has_secure_token :auth_token
      #   end
      #
      #   user = User.new
      #   user.save
      #   user.token # => "pX27zsMN2ViQKta1bGfLmVJE"
      #   user.auth_token # => "77TMHrHJFvFDwodq8w7Ev2m7"
      #   user.regenerate_token # => true
      #   user.regenerate_auth_token # => true
      #
      # SecureRandom::base58 is used to generate the 24-character unique token, so collisions are highly unlikely.
      #
      # Note that it's still possible to generate a race condition in the database in the same way that
      # <tt>validates_uniqueness_of</tt> can. You're encouraged to add a unique index in the database to deal
      # with this even more unlikely scenario.
      def has_secure_token(attribute = :token, options = {})
        # Load securerandom only when has_secure_token is used.
        require 'active_support/core_ext/securerandom'

        before_create_options = { if: options[:if], unless: options[:unless] }

        define_method("regenerate_#{attribute}") { update! attribute => self.class.generate_unique_secure_token }
        before_create(before_create_options) { self.send("#{attribute}=", self.class.generate_unique_secure_token) unless self.send("#{attribute}?")}
      end

      def generate_unique_secure_token
        SecureRandom.base58(24)
      end
    end
  end
end
