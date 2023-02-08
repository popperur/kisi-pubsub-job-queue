require("test_helper")
require("minitest/autorun")

describe(Pubsub::Job::Worker) do
  let(:job_worker) { Pubsub::Job::Worker.new("default") }

  it("can listen") do
    assert_output(/Worker sub initialized, listening on the "default" queue../) do
      job_worker.listen
    end
  end

  it("can clear the queue") do
    assert_output(/The queue has been cleared./) do
      job_worker.clear(immediate: true)
    end
  end

end
