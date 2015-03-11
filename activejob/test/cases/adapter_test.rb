require 'helper'

class AdapterTest < ActiveSupport::TestCase
  test "should load #{ENV['AJ_ADAPTER']} adapter" do
    assert_equal "active_job/queue_adapters/#{ENV['AJ_ADAPTER']}_adapter".classify, ActiveJob::Base.queue_adapter.class.name
  end

  test 'should forbid nonsense arguments' do
    assert_raises(ArgumentError) { ActiveJob::Base.queue_adapter = Mutex }
    assert_raises(ArgumentError) { ActiveJob::Base.queue_adapter = Mutex.new }
  end
end
