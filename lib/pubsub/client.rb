# frozen_string_literal: true

require("google/cloud/pubsub")

module Pubsub

  # == Pubsub Client
  #
  # Includes methods for a pubsub calls to a specific project
  class Client

    # Initializes the pubsub connection
    #
    # @param project_id [String] The id of the project. Defaults to the value of the
    #  +PUBSUB_JOB_QUEUE_PROJECT_ID+ environment variable, if that is not defined, "job_queue" will be used.
    def initialize(project_id: ENV["PUBSUB_JOB_QUEUE_PROJECT_ID"] || "job_queue")
      @project_id = project_id
    end

    # Finds or creates a topic.
    #
    # @param name [String] The name of the topic to find or create
    # @return [Google::Cloud::PubSub::Topic]
    def topic(name)
      project.topic(name) || project.create_topic(name)
    end

    # Finds or creates a subscription.
    #
    # @param name [String] The name of the subscription to find or create
    # @param topic [Google::Cloud::PubSub::Topic] The topic to which the subscription is attached.
    #  If not defined, a topic with the same name will be created.
    # @param ack_deadline [Integer] The ack deadline in seconds. Defaults to 10 minutes (600 seconds)
    # @return [Google::Cloud::PubSub::Subscription]
    def subscription(name, topic: nil, ack_deadline: 600)
      topic ||= topic(name)
      topic.subscription(name) || topic.subscribe(name, deadline: ack_deadline)
    end

    # Retrieves the PubSub project
    #
    # @return [Google::Cloud::PubSub::Project] The PubSub project.
    def project
      @project ||= Google::Cloud::PubSub.new(project_id: @project_id)
    end

  end
end
