require "cases/helper"
require "models/computer"
require "models/developer"
require "models/project"
require "models/topic"
require "models/post"
require "models/comment"

module ActiveRecord
  class CollectionCacheKeyTest < ActiveRecord::TestCase
    fixtures :developers,  :projects, :developers_projects, :topics, :comments, :posts

    test "collection_cache_key on model" do
      assert_match(/\Adevelopers\/query-(\h+)-(\d+)-(\d+)\Z/, Developer.collection_cache_key)
    end

    test "collection_cache_key with custom collection" do
      collection = Topic.where(author_name: "Carl")
      assert_match(/\Atopics\/query-(\h+)-(\d+)-(\d+)\Z/, ActiveRecord::Base.collection_cache_key(collection))
    end

    test "cache_key for relation" do
      developers = Developer.where(name: "David")
      assert_match(/\Adevelopers\/query-(\h+)-(\d+)-(\d+)\Z/, developers.cache_key)
    end

    test "it triggers at most one query" do
      developers =  Developer.where(name: "David")

      assert_queries(1) { developers.cache_key }
      assert_queries(0) { developers.cache_key }
    end

    test "it doesn't trigger any query if the relation is already loaded" do
      developers =  Developer.where(name: "David").load
      assert_queries(0) { developers.cache_key }
    end

    test "relation cache_key changes when the sql query changes" do
      developers = Developer.where(name: "David")
      other_relation =  Developer.where(name: "David").where("1 = 1")

      assert_not_equal developers.cache_key, other_relation.cache_key
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
