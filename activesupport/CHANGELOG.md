*   Add methods `ActiveSupport::Duration#range_from` and 
    `ActiveSupport::Duration#range_until` with corresponding aliases
    ending in `_now`. 
    
        User.where(created_at: 1.week.range_until_now)
        User.where(created_at: 1.week.range_until(3.days.ago)
        
        User.where(birthday: 3.month.range_from_now)
        User.where(birthday: 3.month.range_from(1.month.ago)
        
    *Volodymyr Shatsky*
    
*   Ensure classes which `include Enumerable` get `#to_json` in addition to
    `#as_json`.

    *Sammy Larbi*

*   Change the signature of `fetch_multi` to return a hash rather than an
    array. This makes it consistent with the output of `read_multi`.

    *Parker Selbert*

*   Introduce `Concern#class_methods` as a sleek alternative to clunky
    `module ClassMethods`. Add `Kernel#concern` to define at the toplevel
    without chunky `module Foo; extend ActiveSupport::Concern` boilerplate.

        # app/models/concerns/authentication.rb
        concern :Authentication do
          included do
            after_create :generate_private_key
          end

          class_methods do
            def authenticate(credentials)
              # ...
            end
          end

          def generate_private_key
            # ...
          end
        end

        # app/models/user.rb
        class User < ActiveRecord::Base
          include Authentication
        end

    *Jeremy Kemper*

Please check [4-1-stable](https://github.com/rails/rails/blob/4-1-stable/activesupport/CHANGELOG.md) for previous changes.
