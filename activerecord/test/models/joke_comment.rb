class JokeComment < ActiveRecord::Base
  belongs_to :joke, class_name: 'AJoke', foreign_key: :joke_id
end
