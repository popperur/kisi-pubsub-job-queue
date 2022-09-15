require("test_helper")
require("minitest/autorun")
require("mocha/minitest")

describe(MockJob) do

  it("sleeps for a certain number of seconds") do
    job = MockJob.new
    job.expects(:sleep).with(5)
    job.perform(sleep_duration: 5)
  end

  it("raises a JobError if requested") do
    assert_raises(JobError) do
      MockJob.new.perform(raise_error: true)
    end
  end

end
