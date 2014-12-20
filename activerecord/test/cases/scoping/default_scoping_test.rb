require 'cases/helper'
require 'models/post'
require 'models/comment'
require 'models/developer'
require 'models/computer'

class DefaultScopingTest < ActiveRecord::TestCase
  fixtures :developers, :posts, :comments

  def test_default_scope
    expected = Developer.all.merge!(:order => 'salary DESC').to_a.collect(&:salary)
    received = DeveloperOrderedBySalary.all.collect(&:salary)
    assert_equal expected, received
  end

  def test_default_scope_as_class_method
    assert_equal [developers(:david).becomes(ClassMethodDeveloperCalledDavid)], ClassMethodDeveloperCalledDavid.all
  end

  def test_default_scope_as_class_method_referencing_scope
    assert_equal [developers(:david).becomes(ClassMethodReferencingScopeDeveloperCalledDavid)], ClassMethodReferencingScopeDeveloperCalledDavid.all
  end

  def test_default_scope_as_block_referencing_scope
    assert_equal [developers(:david).becomes(LazyBlockReferencingScopeDeveloperCalledDavid)], LazyBlockReferencingScopeDeveloperCalledDavid.all
  end

  def test_default_scope_with_lambda
    assert_equal [developers(:david).becomes(LazyLambdaDeveloperCalledDavid)], LazyLambdaDeveloperCalledDavid.all
  end

  def test_default_scope_with_block
    assert_equal [developers(:david).becomes(LazyBlockDeveloperCalledDavid)], LazyBlockDeveloperCalledDavid.all
  end

  def test_default_scope_with_callable
    assert_equal [developers(:david).becomes(CallableDeveloperCalledDavid)], CallableDeveloperCalledDavid.all
  end

  def test_default_scope_is_unscoped_on_find
    assert_equal 1, DeveloperCalledDavid.count
    assert_equal 11, DeveloperCalledDavid.unscoped.count
  end

  def test_default_scope_is_unscoped_on_create
    assert_nil DeveloperCalledJamis.unscoped.create!.name
  end

  def test_default_scope_with_conditions_string
    assert_equal Developer.where(name: 'David').map(&:id).sort, DeveloperCalledDavid.all.map(&:id).sort
    assert_equal nil, DeveloperCalledDavid.create!.name
  end

  def test_default_scope_with_conditions_hash
    assert_equal Developer.where(name: 'Jamis').map(&:id).sort, DeveloperCalledJamis.all.map(&:id).sort
    assert_equal 'Jamis', DeveloperCalledJamis.create!.name
  end

  unless in_memory_db?
    def test_default_scoping_with_threads
      2.times do
        Thread.new {
          assert DeveloperOrderedBySalary.all.to_sql.include?('salary DESC')
          DeveloperOrderedBySalary.connection.close
        }.join
      end
    end
  end

  def test_default_scope_with_inheritance
    wheres = InheritedPoorDeveloperCalledJamis.all.where_values_hash
    assert_equal "Jamis", wheres['name']
    assert_equal 50000,   wheres['salary']
  end

  def test_default_scope_with_module_includes
    wheres = ModuleIncludedPoorDeveloperCalledJamis.all.where_values_hash
    assert_equal "Jamis", wheres['name']
    assert_equal 50000,   wheres['salary']
  end

  def test_default_scope_with_multiple_calls
    wheres = MultiplePoorDeveloperCalledJamis.all.where_values_hash
    assert_equal "Jamis", wheres['name']
    assert_equal 50000,   wheres['salary']
  end

  def test_scope_overwrites_default
    expected = Developer.all.merge!(order: 'salary DESC, name DESC').to_a.collect(&:name)
    received = DeveloperOrderedBySalary.by_name.to_a.collect(&:name)
    assert_equal expected, received
  end

  def test_reorder_overrides_default_scope_order
    expected = Developer.order('name DESC').collect(&:name)
    received = DeveloperOrderedBySalary.reorder('name DESC').collect(&:name)
    assert_equal expected, received
  end

  def test_order_after_reorder_combines_orders
    expected = Developer.order('name DESC, id DESC').collect { |dev| [dev.name, dev.id] }
    received = Developer.order('name ASC').reorder('name DESC').order('id DESC').collect { |dev| [dev.name, dev.id] }
    assert_equal expected, received
  end

  def test_unscope_overrides_default_scope
    expected = Developer.all.collect { |dev| [dev.name, dev.id] }
    received = DeveloperCalledJamis.unscope(:where).collect { |dev| [dev.name, dev.id] }
    assert_equal expected, received
  end

  def test_unscope_after_reordering_and_combining
    expected = Developer.order('id DESC, name DESC').collect { |dev| [dev.name, dev.id] }
    received = DeveloperOrderedBySalary.reorder('name DESC').unscope(:order).order('id DESC, name DESC').collect { |dev| [dev.name, dev.id] }
    assert_equal expected, received

    expected_2 = Developer.all.collect { |dev| [dev.name, dev.id] }
    received_2 = Developer.order('id DESC, name DESC').unscope(:order).collect { |dev| [dev.name, dev.id] }
    assert_equal expected_2, received_2

    expected_3 = Developer.all.collect { |dev| [dev.name, dev.id] }
    received_3 = Developer.reorder('name DESC').unscope(:order).collect { |dev| [dev.name, dev.id] }
    assert_equal expected_3, received_3
  end

  def test_unscope_with_where_attributes
    expected = Developer.order('salary DESC').collect(&:name)
    received = DeveloperOrderedBySalary.where(name: 'David').unscope(where: :name).collect(&:name)
    assert_equal expected, received

    expected_2 = Developer.order('salary DESC').collect(&:name)
    received_2 = DeveloperOrderedBySalary.select("id").where("name" => "Jamis").unscope({:where => :name}, :select).collect(&:name)
    assert_equal expected_2, received_2

    expected_3 = Developer.order('salary DESC').collect(&:name)
    received_3 = DeveloperOrderedBySalary.select("id").where("name" => "Jamis").unscope(:select, :where).collect(&:name)
    assert_equal expected_3, received_3

    expected_4 = Developer.order('salary DESC').collect(&:name)
    received_4 = DeveloperOrderedBySalary.where.not("name" => "Jamis").unscope(where: :name).collect(&:name)
    assert_equal expected_4, received_4

    expected_5 = Developer.order('salary DESC').collect(&:name)
    received_5 = DeveloperOrderedBySalary.where.not("name" => ["Jamis", "David"]).unscope(where: :name).collect(&:name)
    assert_equal expected_5, received_5

    expected_6 = Developer.order('salary DESC').collect(&:name)
    received_6 = DeveloperOrderedBySalary.where(Developer.arel_table['name'].eq('David')).unscope(where: :name).collect(&:name)
    assert_equal expected_6, received_6

    expected_7 = Developer.order('salary DESC').collect(&:name)
    received_7 = DeveloperOrderedBySalary.where(Developer.arel_table[:name].eq('David')).unscope(where: :name).collect(&:name)
    assert_equal expected_7, received_7
  end

  def test_unscope_multiple_where_clauses
    expected = Developer.order('salary DESC').collect(&:name)
    received = DeveloperOrderedBySalary.where(name: 'Jamis').where(id: 1).unscope(where: [:name, :id]).collect(&:name)
    assert_equal expected, received
  end

  def test_unscope_string_where_clauses_involved
    dev_relation = Developer.order('salary DESC').where("created_at > ?", 1.year.ago)
    expected = dev_relation.collect(&:name)

    dev_ordered_relation = DeveloperOrderedBySalary.where(name: 'Jamis').where("created_at > ?", 1.year.ago)
    received = dev_ordered_relation.unscope(where: [:name]).collect(&:name)

    assert_equal expected, received
  end

  def test_unscope_with_grouping_attributes
    expected = Developer.order('salary DESC').collect(&:name)
    received = DeveloperOrderedBySalary.group(:name).unscope(:group).collect(&:name)
    assert_equal expected, received

    expected_2 = Developer.order('salary DESC').collect(&:name)
    received_2 = DeveloperOrderedBySalary.group("name").unscope(:group).collect(&:name)
    assert_equal expected_2, received_2
  end

  def test_unscope_with_limit_in_query
    expected = Developer.order('salary DESC').collect(&:name)
    received = DeveloperOrderedBySalary.limit(1).unscope(:limit).collect(&:name)
    assert_equal expected, received
  end

  def test_order_to_unscope_reordering
    scope = DeveloperOrderedBySalary.order('salary DESC, name ASC').reverse_order.unscope(:order)
    assert !(scope.to_sql =~ /order/i)
  end

  def test_unscope_reverse_order
    expected = Developer.all.collect(&:name)
    received = Developer.order('salary DESC').reverse_order.unscope(:order).collect(&:name)
    assert_equal expected, received
  end

  def test_unscope_select
    expected = Developer.order('salary ASC').collect(&:name)
    received = Developer.order('salary DESC').reverse_order.select(:name).unscope(:select).collect(&:name)
    assert_equal expected, received

    expected_2 = Developer.all.collect(&:id)
    received_2 = Developer.select(:name).unscope(:select).collect(&:id)
    assert_equal expected_2, received_2
  end

  def test_unscope_offset
    expected = Developer.all.collect(&:name)
    received = Developer.offset(5).unscope(:offset).collect(&:name)
    assert_equal expected, received
  end

  def test_unscope_joins_and_select_on_developers_projects
    expected = Developer.all.collect(&:name)
    received = Developer.joins('JOIN developers_projects ON id = developer_id').select(:id).unscope(:joins, :select).collect(&:name)
    assert_equal expected, received
  end

  def test_unscope_includes
    expected = Developer.all.collect(&:name)
    received = Developer.includes(:projects).select(:id).unscope(:includes, :select).collect(&:name)
    assert_equal expected, received
  end

  def test_unscope_having
    expected = DeveloperOrderedBySalary.all.collect(&:name)
    received = DeveloperOrderedBySalary.having("name IN ('Jamis', 'David')").unscope(:having).collect(&:name)
    assert_equal expected, received
  end

  def test_unscope_and_scope
    developer_klass = Class.new(Developer) do
      scope :by_name, -> name { unscope(where: :name).where(name: name) }
    end

    expected = developer_klass.where(name: 'Jamis').collect { |dev| [dev.name, dev.id] }
    received = developer_klass.where(name: 'David').by_name('Jamis').collect { |dev| [dev.name, dev.id] }
    assert_equal expected, received
  end

  def test_unscope_errors_with_invalid_value
    assert_raises(ArgumentError) do
      Developer.includes(:projects).where(name: "Jamis").unscope(:stupidly_incorrect_value)
    end

    assert_raises(ArgumentError) do
      Developer.all.unscope(:includes, :select, :some_broken_value)
    end

    assert_raises(ArgumentError) do
      Developer.order('name DESC').reverse_order.unscope(:reverse_order)
    end

    assert_raises(ArgumentError) do
      Developer.order('name DESC').where(name: "Jamis").unscope()
    end
  end

  def test_unscope_errors_with_non_where_hash_keys
    assert_raises(ArgumentError) do
      Developer.where(name: "Jamis").limit(4).unscope(limit: 4)
    end

    assert_raises(ArgumentError) do
      Developer.where(name: "Jamis").unscope("where" => :name)
    end
  end

  def test_unscope_errors_with_non_symbol_or_hash_arguments
    assert_raises(ArgumentError) do
      Developer.where(name: "Jamis").limit(3).unscope("limit")
    end

    assert_raises(ArgumentError) do
      Developer.select("id").unscope("select")
    end

    assert_raises(ArgumentError) do
      Developer.select("id").unscope(5)
    end
  end

  def test_unscope_merging
    merged = Developer.where(name: "Jamis").merge(Developer.unscope(:where))
    assert merged.where_clause.empty?
    assert !merged.where(name: "Jon").where_clause.empty?
  end

  def test_order_in_default_scope_should_not_prevail
    expected = Developer.all.merge!(order: 'salary desc').to_a.collect(&:salary)
    received = DeveloperOrderedBySalary.all.merge!(order: 'salary').to_a.collect(&:salary)
    assert_equal expected, received
  end

  def test_create_attribute_overwrites_default_scoping
    assert_equal 'David', PoorDeveloperCalledJamis.create!(:name => 'David').name
    assert_equal 200000, PoorDeveloperCalledJamis.create!(:name => 'David', :salary => 200000).salary
  end

  def test_create_attribute_overwrites_default_values
    assert_equal nil, PoorDeveloperCalledJamis.create!(:salary => nil).salary
    assert_equal 50000, PoorDeveloperCalledJamis.create!(:name => 'David').salary
  end

  def test_default_scope_attribute
    jamis = PoorDeveloperCalledJamis.new(:name => 'David')
    assert_equal 50000, jamis.salary
  end

  def test_where_attribute
    aaron = PoorDeveloperCalledJamis.where(:salary => 20).new(:name => 'Aaron')
    assert_equal 20, aaron.salary
    assert_equal 'Aaron', aaron.name
  end

  def test_where_attribute_merge
    aaron = PoorDeveloperCalledJamis.where(:name => 'foo').new(:name => 'Aaron')
    assert_equal 'Aaron', aaron.name
  end

  def test_scope_composed_by_limit_and_then_offset_is_equal_to_scope_composed_by_offset_and_then_limit
    posts_limit_offset = Post.limit(3).offset(2)
    posts_offset_limit = Post.offset(2).limit(3)
    assert_equal posts_limit_offset, posts_offset_limit
  end

  def test_create_with_merge
    aaron = PoorDeveloperCalledJamis.create_with(:name => 'foo', :salary => 20).merge(
              PoorDeveloperCalledJamis.create_with(:name => 'Aaron')).new
    assert_equal 20, aaron.salary
    assert_equal 'Aaron', aaron.name

    aaron = PoorDeveloperCalledJamis.create_with(:name => 'foo', :salary => 20).
                                     create_with(:name => 'Aaron').new
    assert_equal 20, aaron.salary
    assert_equal 'Aaron', aaron.name
  end

  def test_create_with_reset
    jamis = PoorDeveloperCalledJamis.create_with(:name => 'Aaron').create_with(nil).new
    assert_equal 'Jamis', jamis.name
  end

  # FIXME: I don't know if this is *desired* behavior, but it is *today's*
  # behavior.
  def test_create_with_empty_hash_will_not_reset
    jamis = PoorDeveloperCalledJamis.create_with(:name => 'Aaron').create_with({}).new
    assert_equal 'Aaron', jamis.name
  end

  def test_unscoped_with_named_scope_should_not_have_default_scope
    assert_equal [DeveloperCalledJamis.find(developers(:poor_jamis).id)], DeveloperCalledJamis.poor

    assert DeveloperCalledJamis.unscoped.poor.include?(developers(:david).becomes(DeveloperCalledJamis))

    assert_equal 11, DeveloperCalledJamis.unscoped.length
    assert_equal 1,  DeveloperCalledJamis.poor.length
    assert_equal 10, DeveloperCalledJamis.unscoped.poor.length
    assert_equal 10, DeveloperCalledJamis.unscoped { DeveloperCalledJamis.poor }.length
  end

  def test_default_scope_with_joins
    assert_equal Comment.where(post_id: SpecialPostWithDefaultScope.pluck(:id)).count,
                 Comment.joins(:special_post_with_default_scope).count
    assert_equal Comment.where(post_id: Post.pluck(:id)).count,
                 Comment.joins(:post).count
  end

  def test_unscoped_with_joins_should_not_have_default_scope
    assert_equal SpecialPostWithDefaultScope.unscoped { Comment.joins(:special_post_with_default_scope).to_a },
                 Comment.joins(:post).to_a
  end

  def test_default_scope_select_ignored_by_aggregations
    assert_equal DeveloperWithSelect.all.to_a.count, DeveloperWithSelect.count
  end

  def test_default_scope_select_ignored_by_grouped_aggregations
    assert_equal Hash[Developer.all.group_by(&:salary).map { |s, d| [s, d.count] }],
                 DeveloperWithSelect.group(:salary).count
  end

  def test_default_scope_order_ignored_by_aggregations
    assert_equal DeveloperOrderedBySalary.all.count, DeveloperOrderedBySalary.count
  end

  def test_default_scope_find_last
    assert DeveloperOrderedBySalary.count > 1, "need more than one row for test"

    lowest_salary_dev = DeveloperOrderedBySalary.find(developers(:poor_jamis).id)
    assert_equal lowest_salary_dev, DeveloperOrderedBySalary.last
  end

  def test_default_scope_include_with_count
    d = DeveloperWithIncludes.create!
    d.audit_logs.create! :message => 'foo'

    assert_equal 1, DeveloperWithIncludes.where(:audit_logs => { :message => 'foo' }).count
  end

  def test_default_scope_with_references_works_through_collection_association
    post = PostWithCommentWithDefaultScopeReferencesAssociation.create!(title: "Hello World", body: "Here we go.")
    comment = post.comment_with_default_scope_references_associations.create!(body: "Great post.", developer_id: Developer.first.id)
    assert_equal comment, post.comment_with_default_scope_references_associations.to_a.first
  end

  def test_default_scope_with_references_works_through_association
    post = PostWithCommentWithDefaultScopeReferencesAssociation.create!(title: "Hello World", body: "Here we go.")
    comment = post.comment_with_default_scope_references_associations.create!(body: "Great post.", developer_id: Developer.first.id)
    assert_equal comment, post.first_comment
  end

  def test_default_scope_with_references_works_with_find_by
    post = PostWithCommentWithDefaultScopeReferencesAssociation.create!(title: "Hello World", body: "Here we go.")
    comment = post.comment_with_default_scope_references_associations.create!(body: "Great post.", developer_id: Developer.first.id)
    assert_equal comment, CommentWithDefaultScopeReferencesAssociation.find_by(id: comment.id)
  end

  unless in_memory_db?
    def test_default_scope_is_threadsafe
      threads = []
      assert_not_equal 1, ThreadsafeDeveloper.unscoped.count

      threads << Thread.new do
        Thread.current[:long_default_scope] = true
        assert_equal 1, ThreadsafeDeveloper.all.to_a.count
        ThreadsafeDeveloper.connection.close
      end
      threads << Thread.new do
        assert_equal 1, ThreadsafeDeveloper.all.to_a.count
        ThreadsafeDeveloper.connection.close
      end
      threads.each(&:join)
    end
  end

  test "additional conditions are ANDed with the default scope" do
    scope = DeveloperCalledJamis.where(name: "David")
    assert_equal 2, scope.where_clause.ast.children.length
    assert_equal [], scope.to_a
  end

  test "additional conditions in a scope are ANDed with the default scope" do
    scope = DeveloperCalledJamis.david
    assert_equal 2, scope.where_clause.ast.children.length
    assert_equal [], scope.to_a
  end

  test "a scope can remove the condition from the default scope" do
    scope = DeveloperCalledJamis.david2
    assert_equal 1, scope.where_clause.ast.children.length
    assert_equal Developer.where(name: "David"), scope
  end
end
