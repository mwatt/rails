require "cases/helper"
require "models/computer"
require "models/developer"
require "models/project"
require "models/topic"

module ActiveRecord
  class CollectionCacheKeyTest < ActiveRecord::TestCase
    fixtures :developers,  :projects, :developers_projects, :topics

    test "relation cache_key" do
      developers = Developer.where(name: "David")
      assert_match(/\Adevelopers\/query-(\h+)-(\d+)-(\d+)\Z/, developers.cache_key)
    end

    test "cache_key for empty relation" do
      developers = Developer.where(name: "Non Existent Developer")
      assert_match(/\Adevelopers\/query-(\h+)-0\Z/, developers.cache_key)
    end

    test "cache_key with custom timestamp column" do
      topics = Topic.where("title like ?", "%Topic%")
      last_topic_timestamp = topics(:fifth).written_on.utc.to_s(:nsec)
      assert_match(last_topic_timestamp, topics.cache_key(:written_on))
    end

    test "collection proxy provides a cache_key" do
      developers = projects(:active_record).developers
      assert_match(/\Adevelopers\/query-(\h+)-(\d+)-(\d+)\Z/, developers.cache_key)
    end
  end
end
