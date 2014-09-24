require 'helper'

module ActiveJob
  module QueueAdapters
    module StubOneAdapter; end
    module StubTwoAdapter; end
  end
end

class AdapterTest < ActiveSupport::TestCase
  test "should load #{ENV['AJ_ADAPTER']} adapter" do
    assert_equal "active_job/queue_adapters/#{ENV['AJ_ADAPTER']}_adapter".classify, ActiveJob::Base.queue_adapter.name
  end

  test 'should allow overriding the queue_adapter at the child class level without affecting the parent or its sibling' do
    base_queue_adapter = ActiveJob::Base.queue_adapter

    child_job_one = Class.new(ActiveJob::Base)
    child_job_one.queue_adapter = :stub_one

    assert_not_equal ActiveJob::Base.queue_adapter, child_job_one.queue_adapter
    assert_equal ActiveJob::QueueAdapters::StubOneAdapter, child_job_one.queue_adapter

    child_job_two = Class.new(ActiveJob::Base)
    child_job_two.queue_adapter = :stub_two

    assert_equal ActiveJob::QueueAdapters::StubTwoAdapter, child_job_two.queue_adapter
    assert_equal ActiveJob::QueueAdapters::StubOneAdapter, child_job_one.queue_adapter, "child_job_one's queue adapter should remain unchanged"
    assert_equal base_queue_adapter, ActiveJob::Base.queue_adapter, "ActiveJob::Base's queue adapter should remain unchanged"

    child_job_three = Class.new(ActiveJob::Base)

    assert_not_nil child_job_three.queue_adapter
  end
end
