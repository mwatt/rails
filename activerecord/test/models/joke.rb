class Joke < ActiveRecord::Base
  self.table_name = 'funny_jokes'
end

class GoodJoke < ActiveRecord::Base
  self.table_name = 'funny_jokes'
end

class AJoke < ActiveRecord::Base
  self.table_name = 'awesome_jokes'

  has_many :comments, class_name: 'JokeComment', foreign_key: :joke_id
end
