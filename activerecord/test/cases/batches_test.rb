require 'cases/helper'
require 'models/post'
require 'models/subscriber'

class EachTest < ActiveRecord::TestCase
  fixtures :posts, :subscribers

  def setup
    @posts = Post.order("id asc")
    @total = Post.count
    Post.count('id') # preheat arel's table cache
  end

  def test_each_should_execute_one_query_per_batch
    assert_deprecated do
      assert_queries(@total + 1) do
        Post.find_each(:batch_size => 1) do |post|
          assert_kind_of Post, post
        end
      end
    end
  end

  def test_each_should_not_return_query_chain_and_execute_two_query
    assert_deprecated do
      assert_queries(1) do
        result = Post.find_each(:batch_size => 100000){ }
        assert_nil result
      end
    end
  end

  def test_each_should_return_an_enumerator_if_no_block_is_present
    assert_deprecated do
      assert_queries(1) do
        Post.find_each(:batch_size => 100000).with_index do |post, index|
          assert_kind_of Post, post
          assert_kind_of Integer, index
        end
      end
    end
  end

  if Enumerator.method_defined? :size
    def test_each_should_return_a_sized_enumerator
      assert_deprecated do
        assert_equal 11, Post.find_each(batch_size: 1).size
        assert_equal 5, Post.find_each(batch_size:  2, begin_at: 7).size
        assert_equal 11, Post.find_each(batch_size: 10_000).size
      end
    end
  end

  def test_each_enumerator_should_execute_one_query_per_batch
    assert_deprecated do
      assert_queries(@total + 1) do
        Post.find_each(:batch_size => 1).with_index do |post, index|
          assert_kind_of Post, post
          assert_kind_of Integer, index
        end
      end
    end
  end

  def test_each_should_execute_if_id_is_in_select
    assert_deprecated do
      assert_queries(6) do
        Post.select("id, title, type").find_each(:batch_size => 2) do |post|
          assert_kind_of Post, post
        end
      end
    end
  end

  def test_warn_if_limit_scope_is_set
    ActiveRecord::Base.logger.expects(:warn)
    assert_deprecated do
      Post.limit(1).find_each { |post| post }
    end
  end

  def test_warn_if_order_scope_is_set
    ActiveRecord::Base.logger.expects(:warn)
    assert_deprecated do
      Post.order("title").find_each { |post| post }
    end
  end

  def test_logger_not_required
    previous_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil
    assert_deprecated do
      assert_nothing_raised do
        Post.limit(1).find_each { |post| post }
      end
    end
  ensure
    ActiveRecord::Base.logger = previous_logger
  end

  def test_find_in_batches_should_return_batches
    assert_deprecated do
      assert_queries(@total + 1) do
        Post.find_in_batches(:batch_size => 1) do |batch|
          assert_kind_of Array, batch
          assert_kind_of Post, batch.first
        end
      end
    end
  end

  def test_find_in_batches_should_start_from_the_start_option
    assert_deprecated do
      assert_queries(@total) do
        Post.find_in_batches(batch_size: 1, begin_at: 2) do |batch|
          assert_kind_of Array, batch
          assert_kind_of Post, batch.first
        end
      end
    end
  end

  def test_find_in_batches_should_end_at_the_end_option
    assert_deprecated do
      assert_queries(6) do
        Post.find_in_batches(batch_size: 1, end_at: 5) do |batch|
          assert_kind_of Array, batch
          assert_kind_of Post, batch.first
        end
      end
    end
  end

  def test_find_in_batches_shouldnt_execute_query_unless_needed
    assert_deprecated do
      assert_queries(2) do
        Post.find_in_batches(:batch_size => @total) {|batch| assert_kind_of Array, batch }
      end
    end

    assert_deprecated do
      assert_queries(1) do
        Post.find_in_batches(:batch_size => @total + 1) {|batch| assert_kind_of Array, batch }
      end
    end
  end

  def test_find_in_batches_should_quote_batch_order
    c = Post.connection
    assert_deprecated do
      assert_sql(/ORDER BY #{c.quote_table_name('posts')}.#{c.quote_column_name('id')}/) do
        Post.find_in_batches(:batch_size => 1) do |batch|
          assert_kind_of Array, batch
          assert_kind_of Post, batch.first
        end
      end
    end
  end

  def test_find_in_batches_should_not_use_records_after_yielding_them_in_case_original_array_is_modified
    not_a_post = "not a post"
    not_a_post.stubs(:id).raises(StandardError, "not_a_post had #id called on it")

    assert_deprecated do
      assert_nothing_raised do
        Post.find_in_batches(:batch_size => 1) do |batch|
          assert_kind_of Array, batch
          assert_kind_of Post, batch.first

          batch.map! { not_a_post }
        end
      end
    end
  end

  def test_find_in_batches_should_ignore_the_order_default_scope
    # First post is with title scope
    first_post = PostWithDefaultScope.first
    posts = []
    assert_deprecated do
      PostWithDefaultScope.find_in_batches  do |batch|
        posts.concat(batch)
      end
    end
    # posts.first will be ordered using id only. Title order scope should not apply here
    assert_not_equal first_post, posts.first
    assert_equal posts(:welcome), posts.first
  end

  def test_find_in_batches_should_not_ignore_the_default_scope_if_it_is_other_then_order
    special_posts_ids = SpecialPostWithDefaultScope.all.map(&:id).sort
    posts = []
    assert_deprecated do
      SpecialPostWithDefaultScope.find_in_batches do |batch|
        posts.concat(batch)
      end
    end
    assert_equal special_posts_ids, posts.map(&:id)
  end

  def test_find_in_batches_should_not_modify_passed_options
    assert_deprecated do
      assert_nothing_raised do
        Post.find_in_batches({ batch_size: 42, begin_at: 1 }.freeze){}
      end
    end
  end

  def test_find_in_batches_should_use_any_column_as_primary_key
    nick_order_subscribers = Subscriber.order('nick asc')
    start_nick = nick_order_subscribers.second.nick

    subscribers = []
    assert_deprecated do
      Subscriber.find_in_batches(batch_size: 1, begin_at: start_nick) do |batch|
        subscribers.concat(batch)
      end
    end

    assert_equal nick_order_subscribers[1..-1].map(&:id), subscribers.map(&:id)
  end

  def test_find_in_batches_should_use_any_column_as_primary_key_when_start_is_not_specified
    assert_deprecated do
      assert_queries(Subscriber.count + 1) do
        Subscriber.find_in_batches(batch_size: 1) do |batch|
          assert_kind_of Array, batch
          assert_kind_of Subscriber, batch.first
        end
      end
    end
  end

  def test_find_in_batches_should_return_an_enumerator
    enum = nil
    assert_deprecated do
      assert_queries(0) do
        enum = Post.find_in_batches(:batch_size => 1)
      end
    end
    assert_deprecated do
      assert_queries(4) do
        enum.first(4) do |batch|
          assert_kind_of Array, batch
          assert_kind_of Post, batch.first
        end
      end
    end
  end

  def test_in_batches_should_not_be_loaded
    Post.in_batches(of: 1) do |relation|
      assert_not relation.loaded?
    end

    Post.in_batches(of: 1, load: false) do |relation|
      assert_not relation.loaded?
    end
  end

  def test_in_batches_should_be_loaded
    Post.in_batches(of: 1, load: true) do |relation|
      assert relation.loaded?
    end
  end

  def test_in_batches_if_not_loaded_executes_more_queries
    assert_queries(@total * 2 + 1) do
      Post.in_batches(of: 1, load: false) do |relation|
        assert_kind_of ActiveRecord::Relation, relation
        assert_kind_of Post, relation.first
      end
    end
  end

  def test_in_batches_should_return_relationes
    assert_queries(@total + 1) do
      Post.in_batches(of: 1) do |relation|
        assert_kind_of ActiveRecord::Relation, relation
      end
    end
  end

  def test_in_batches_should_start_from_the_start_option
    assert_queries(@total) do
      Post.in_batches(of: 1, begin_at: 2) do |relation|
        assert_kind_of ActiveRecord::Relation, relation
      end
    end
  end

  def test_in_batches_should_end_at_the_end_option
    assert_queries(5 + 1) do
      Post.in_batches(of: 1, end_at: 5) do |relation|
        assert_kind_of ActiveRecord::Relation, relation
      end
    end
  end

  def test_in_batches_shouldnt_execute_query_unless_needed
    assert_queries(1 + 1) do
      Post.in_batches(of: @total) {|relation| assert_kind_of ActiveRecord::Relation, relation }
    end

    assert_queries(1) do
      Post.in_batches(of: @total + 1) {|relation| assert_kind_of ActiveRecord::Relation, relation }
    end
  end

  def test_in_batches_should_quote_batch_order
    c = Post.connection
    assert_sql(/ORDER BY #{c.quote_table_name('posts')}.#{c.quote_column_name('id')}/) do
      Post.in_batches(of: 1) do |relation|
        assert_kind_of ActiveRecord::Relation, relation
        assert_kind_of Post, relation.first
      end
    end
  end

  def test_in_batches_should_not_use_records_after_yielding_them_in_case_original_array_is_modified
    not_a_post = "not a post"
    not_a_post.stubs(:id).raises(StandardError, "not_a_post had #id called on it")

    assert_nothing_raised do
      Post.in_batches(of: 1) do |relation|
        assert_kind_of ActiveRecord::Relation, relation
        assert_kind_of Post, relation.first

        relation = [not_a_post] * relation.count
      end
    end
  end

  def test_in_batches_should_ignore_the_order_default_scope
    # First post is with title scope
    first_post = PostWithDefaultScope.first
    posts = []
    PostWithDefaultScope.in_batches do |relation|
      posts.concat(relation)
    end
    # posts.first will be ordered using id only. Title order scope should not apply here
    assert_not_equal first_post, posts.first
    assert_equal posts(:welcome), posts.first
  end

  def test_in_batches_should_not_ignore_the_default_scope_if_it_is_other_then_order
    special_posts_ids = SpecialPostWithDefaultScope.all.map(&:id).sort
    posts = []
    SpecialPostWithDefaultScope.in_batches do |relation|
      posts.concat(relation)
    end
    assert_equal special_posts_ids, posts.map(&:id)
  end

  def test_in_batches_should_not_modify_passed_options
    assert_nothing_raised do
      Post.in_batches({ of: 42, begin_at: 1 }.freeze){}
    end
  end

  def test_in_batches_should_use_any_column_as_primary_key
    nick_order_subscribers = Subscriber.order('nick asc')
    start_nick = nick_order_subscribers.second.nick

    subscribers = []
    Subscriber.in_batches(of: 1, begin_at: start_nick) do |relation|
      subscribers.concat(relation)
    end

    assert_equal nick_order_subscribers[1..-1].map(&:id), subscribers.map(&:id)
  end

  def test_in_batches_should_use_any_column_as_primary_key_when_start_is_not_specified
    assert_queries(Subscriber.count + 1) do
      Subscriber.in_batches(of: 1, load: true) do |relation|
        assert_kind_of ActiveRecord::Relation, relation
        assert_kind_of Subscriber, relation.first
      end
    end
  end

  def test_in_batches_should_return_an_enumerator
    enum = nil
    assert_queries(0) do
      enum = Post.in_batches(of: 1)
    end
    assert_queries(4) do
      enum.first(4) do |relation|
        assert_kind_of ActiveRecord::Relation, relation
        assert_kind_of Post, relation.first
      end
    end
  end

  def test_find_in_batches_start_deprecated
    assert_deprecated do
      assert_queries(@total) do
        Post.find_in_batches(batch_size: 1, start: 2) do |batch|
          assert_kind_of Array, batch
          assert_kind_of Post, batch.first
        end
      end
    end
  end

  def test_find_each_start_deprecated
    assert_deprecated do
      assert_queries(@total) do
        Post.find_each(batch_size: 1, start: 2) do |post|
          assert_kind_of Post, post
        end
      end
    end
  end

  if Enumerator.method_defined? :size
    def test_find_in_batches_should_return_a_sized_enumerator
      assert_deprecated do
        assert_equal 11, Post.find_in_batches(:batch_size => 1).size
        assert_equal 6, Post.find_in_batches(:batch_size => 2).size
        assert_equal 4, Post.find_in_batches(batch_size: 2, begin_at: 4).size
        assert_equal 4, Post.find_in_batches(:batch_size => 3).size
        assert_equal 1, Post.find_in_batches(:batch_size => 10_000).size
      end
    end
  end
end
