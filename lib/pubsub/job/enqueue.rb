# frozen_string_literal: true

module Pubsub
  module Job

    # == Pubsub Job Enqueue
    #
    # Includes methods for enqueueing an active job to Pub/Sub
    class Enqueue

      # Used for the test suite.
      attr_writer(:immediate)

      # Initializes a new Enqueue.
      # @param logger [Logger] logger to use. Defaults to 'stdout'.
      def initialize(logger: Logger.new($stdout))
        @logger = logger
        @immediate = false
      end

      # Enqueues a job to be performed.
      # The job is sent to pubsub asynchronously,
      # read more about +publish_async+ {here}[https://cloud.google.com/ruby/docs/reference/google-cloud-pubsub/latest/Google-Cloud-PubSub-AsyncPublisher].
      # @param job_data [Hash] The job to be performed.
      # @param scheduled_at [Float] The time to perform the job. Defaults to the current time.
      # @param queue_name [String] The name of the queue. Defaults to 'default'.
      def enqueue(job_data, scheduled_at: Time.now.to_f, queue_name: "default")
        @logger.debug("Enqueueing job \"#{job_data['job_id']}\" to the \"#{queue_name}\" queue..")
        message = job_data.to_json
        attributes = { scheduled_at: scheduled_at }
        if @immediate
          queue(queue_name).publish(message, **attributes)
        else
          queue(queue_name).publish_async(message, **attributes) do |result|
            @logger.error(result.error) unless result.succeeded?
          end
        end
      end

      # Executes a shutdown
      # @param wait [Boolean] If 'true', waits for the termination. Defaults to 'true'.
      def shutdown(wait: true)
        shutdown_async_publishers(wait: wait)
      end

      private

      # Finds or creates a queue topic.
      # @param name [String] The name of the queue.
      # @return [Google::Cloud::PubSub::Topic]
      def queue(name)
        queue_topic_map[name] ||= pubsub_client.topic(name)
      end

      # Stops the async publishers
      # @param wait [Boolean] If 'true', waits for the termination. Defaults to 'true'.
      def shutdown_async_publishers(wait: true)
        queue_topic_map.values do |topic|
          publisher = topic.async_publisher&.stop
          publisher.wait! if publisher && wait
        end
        @logger.info("Shutdown of async publishers complete.")
      end

      # Retrieves the queue topic map
      # @return [Hash] The queue topic map
      def queue_topic_map
        @queue_topic_map ||= {}
      end

      # Creates or retrieves the pubsub client
      # @return [Pubsub::Client] The pubsub client
      def pubsub_client
        @pubsub_client ||= Pubsub::Client.new
      end

    end
  end
end

