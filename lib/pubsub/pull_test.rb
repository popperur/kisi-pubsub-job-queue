# frozen_string_literal: true

# Simple pub/sub PULL Test coming from here.
# https://github.com/googleapis/google-cloud-ruby/issues/4103
#
# Usage:
#
# - Open console
#   $ docker compose exec web rails console
# - Execute
#   > require 'pubsub/pull_test';pt = PullTest.new;pt.go
#

LOGGER = Logger.new($stdout)

module PrependedPubSubLogger

  def publish(topic, messages)
    start = Time.now
    response = super
    LOGGER.info("publish #{messages.count}: #{start.strftime("%T")}(#{Time.now - start})")
    response
  end

  ##
  # Acknowledges receipt of a message.
  def acknowledge(subscription, *ack_ids)
    start = Time.now
    response = super
    LOGGER.info("acknowledge #{ack_ids.count}: #{start.strftime("%T")}(#{Time.now - start})")
    response
  end

  ##
  # Modifies the ack deadline for a specific message.
  def modify_ack_deadline(subscription, ids, deadline)
    start = Time.now
    response = super
    LOGGER.info("modify_ack_deadline #{ids.count}, #{deadline}: #{start.strftime("%T")}(#{Time.now - start})")
    response
  end
end

class PullTest
  def initialize(ack_deadline: 10)
    @ack_deadline = ack_deadline
  end

  def go
    pubsub = Google::Cloud::PubSub.new(project_id: "job_queue")

    # Prepend a module to print when RPCs are called.
    pubsub.service.class.prepend(PrependedPubSubLogger)

    LOGGER.info("Creating subscription with ack_deadline: #{@ack_deadline}")
    name = SecureRandom.hex
    topic = pubsub.create_topic("topic-#{name}")
    sub = topic.subscribe("sub-#{name}", deadline: @ack_deadline)

    subscriber = sub.listen do |msg|
      LOGGER.info("Start #{msg.data}")
      sleep(22)
      msg.acknowledge!
      LOGGER.info("Stop #{msg.data}")
    end
    subscriber.on_error { |e| LOGGER.error(e.message); Thread.main.raise(e) }
    subscriber.start

    sleep(3)
    topic.publish("msg1")
    sleep(1)
    topic.publish("msg2")
    sleep(120)

    subscriber.stop
    subscriber.wait!

    sub.delete
    topic.delete
  end
end