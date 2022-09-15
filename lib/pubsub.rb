# frozen_string_literal: true

require("google/cloud/pubsub")

# == Pubsub
#
# Includes methods for a pubsub calls to a specific project
class Pubsub

  # Initializes the pubsub connection
  #
  # @param project_id [String] The id of the project
  def initialize(project_id)
    @project = Google::Cloud::PubSub.new(project_id: project_id)
  end

  # Finds or creates a topic.
  #
  # @param name [String] The name of the topic to find or create
  # @return [Google::Cloud::PubSub::Topic]
  def topic(name)
    @project.topic(name) || @project.create_topic(name)
  end

  # Finds or creates a subscription.
  #
  # @param topic [Google::Cloud::PubSub::Topic] The topic
  # @param name [String] The name of the subscription to find or create
  # @return [Google::Cloud::PubSub::Subscription]
  def subscription(topic, name)
    topic.subscription(name) || topic.subscribe(name)
  end

end
