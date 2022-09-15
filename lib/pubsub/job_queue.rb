# frozen_string_literal: true

module Pubsub

  # == Pubsub Job Queue
  #
  # Includes methods for a pubsub-based queueing backend.
  class JobQueue

    QUEUE_MORGUE = "morgue"

    # Used for the test suite.
    attr_writer(:immediate_publish) # :nodoc:

    # Initializes the object. The id of the pubsub project is retrieved from the
    # +PUBSUB_JOB_QUEUE_PROJECT_ID+ environment variable, if not defined, "job_queue" will be used.
    def initialize(logger: Logger.new($stdout))
      @pubsub = Pubsub::Connection.new(ENV["PUBSUB_JOB_QUEUE_PROJECT_ID"] || "job_queue")
      @logger = logger
      @queue_topic_map = {}
    end

    # Finds or creates a queue worker subscription.
    #
    # @param queue_name [String] The name of the queue
    # @return [Google::Cloud::PubSub::Subscription]
    def worker_sub(queue_name)
      topic = queue(queue_name)
      @pubsub.subscription(topic, queue_name)
    end

    # Enqueues a job to be performed.
    #
    # The job is sent to pubsub asynchronously,
    # read more about +publish_async+ {here}[https://cloud.google.com/ruby/docs/reference/google-cloud-pubsub/latest/Google-Cloud-PubSub-AsyncPublisher].
    # @param job [ActiveJob::Base] The job to be performed.
    # @param scheduled_at [Float] The time to perform the job. If not defined, the current time will be used.
    def enqueue(job, scheduled_at: Time.now)
      message = job.serialize.to_json
      attributes = { scheduled_at: scheduled_at }
      if @immediate_publish
        queue(job.queue_name).publish(message, **attributes)
      else
        queue(job.queue_name).publish_async(message, **attributes) do |result|
          @logger.error(result.error) unless result.succeeded?
        end
      end
    end

    # Clears the queue by pulling and acknowledging all jobs without processing them.
    # The Pub/Sub system sometimes does not return all jobs during a direct pull, so
    # the pull is repeated until all jobs are received.
    #
    # @param queue_name [String] The name of the queue.
    def clear(queue_name)
      sub = worker_sub(queue_name)
      loop do
        @logger.info("Clearing the \"#{queue_name}\" queue, please wait..")
        messages = sub.pull(immediate: false)
        sub.acknowledge(messages) unless messages.empty?
        @logger.info("The number of removed messages: #{messages.length}.")
        break if messages.empty?
      end
      @logger.info("The queue has been cleared.")
    end

    # Executes a shutdown
    #
    # @param wait [Boolean] if true, waits for the termination
    def shutdown(wait: true)
      shutdown_async_publishers(wait: wait)
    end

    private

    # Finds or creates a queue topic.
    #
    # @param name [String] The name of the queue.
    # @return [Google::Cloud::PubSub::Topic]
    def queue(name)
      @queue_topic_map[name] ||= @pubsub.topic(name)
    end

    # Finds or creates the morgue queue topic.
    def queue_morgue
      queue(QUEUE_MORGUE)
    end

    # Stops the async publishers
    #
    # @param wait [Boolean] if true, waits for the termination
    def shutdown_async_publishers(wait: true)
      @queue_topic_map.values do |topic|
        publisher = topic.async_publisher&.stop
        publisher.wait! if publisher && wait
      end
      @logger.info("Shutdown of async publishers complete.")
    end

  end
end

