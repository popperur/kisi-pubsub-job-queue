# frozen_string_literal: true

module ActiveJob
  module QueueAdapters
    class PubsubAdapter

      def initialize
        @job_queue = Pubsub::JobQueue.new
      end

      # Enqueues a job to be performed.
      #
      # @param [ActiveJob::Base] job The job to be performed.
      def enqueue(job)
        @job_queue.enqueue(job)
      end

      # Enqueues a job to be performed at a certain time.
      #
      # @param [ActiveJob::Base] job The job to be performed.
      # @param [Float] timestamp The time to perform the job.
      def enqueue_at(job, timestamp)
        @job_queue.enqueue(job, scheduled_at: timestamp)
      end

      # Gracefully stops enqueuing jobs.
      # Waits for termination by default. Pass `wait: false` to continue.
      #
      # @param wait [Boolean] if true, waits for the termination
      def shutdown(wait: true)
        @job_queue.shutdown(wait: wait)
      end

    end
  end
end
