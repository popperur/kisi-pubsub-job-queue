# frozen_string_literal: true

module ActiveJob
  module QueueAdapters
    class PubsubAdapter

      def initialize
        @handler = Pubsub::Job::Enqueue.new
      end

      # Enqueues a job to be performed.
      #
      # @param [ActiveJob::Base] job The job to be performed.
      def enqueue(job)
        enqueue_at(job, Time.now.to_f)
      end

      # Enqueues a job to be performed at a certain time.
      #
      # @param [ActiveJob::Base] job The job to be performed.
      # @param [Float] timestamp The time to perform the job.
      def enqueue_at(job, timestamp)
        @handler.enqueue(job.serialize, scheduled_at: timestamp, queue_name: job.queue_name)
      end

      # Gracefully stops enqueuing jobs.
      # Waits for termination by default. Pass `wait: false` to continue.
      #
      # @param wait [Boolean] if true, waits for the termination
      def shutdown(wait: true)
        @handler.shutdown(wait: wait)
      end

    end
  end
end
