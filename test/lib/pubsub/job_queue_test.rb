require("test_helper")
require("minitest/autorun")

module Pubsub

  class JobQueueTest < ActiveJob::TestCase

    describe("Pubsub Job Queue") do

      let(:pubsub_job_queue) { Pubsub::JobQueue.new }

      it("retrieves a queue worker subscription") do
        worker_sub = pubsub_job_queue.worker_sub('default')
        expect(worker_sub).wont_be_nil
        expect(worker_sub.name).must_equal("projects/job_queue/subscriptions/default")
      end

      it("enqueues a job") do
        pubsub_job_queue.immediate_publish = true
        message = pubsub_job_queue.enqueue(MockJob.new)
        expect(message.attributes["scheduled_at"]).wont_be_nil
      end

      it("enqueues a job to be performed in the future") do
        pubsub_job_queue.immediate_publish = true
        timestamp = Date.tomorrow.noon.to_f
        message = pubsub_job_queue.enqueue(MockJob.new, scheduled_at: timestamp)
        # verify if timestamp is stored as a message attribute
        expect(message.attributes["scheduled_at"]).wont_be_nil
        expect(message.attributes["scheduled_at"].to_f).must_equal(timestamp)
      end

    end

  end
end
