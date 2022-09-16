# The Kisi Backend Code Challenge

Greetings, Earthling!

Welcome to the Kisi Backend Code Challenge. This challenge will be used to assess your familiarity with the Ruby programming language, the Rails framework and general coding best practices. There are no hard time limits, but we’re trying to keep the scope limited so we don’t occupy too much of your time. We will not use any of the results for our production systems. Our aim is to have an efficient and fair assessment: you spend time solving the challenge, and we spend time giving you detailed feedback.

We know the task is hard, which is why we have provided some hints. You are welcome to ask if you have specific questions - just reach out to your recruiter.

These are the steps:

1. Clone or download the [kisi-api-challenge](https://github.com/kisi-inc/kisi-api-challenge) repository. You may use this as a starting point for your solution.
2. Solve the challenge.
3. Submit your solution to a private GitHub repository. Include a `README.md` with instructions on how to run the code. Share access to the repository with `ce07c3` and `jensljungblad`.
4. Create a pull request that includes all of your changes on top of the above provided repository. Request a review from `ce07c3`.

## The challenge

Build a very simple background job system to use with Rails based on [GCP Pub/Sub][gcp-pubsub].

The idea is to build a background job system that is compatible with the [ActiveJob][activejob-basics] interface of Rails and allows Rails developers to easily enqueue jobs to a Google Pub/Sub backend. Additionally, a rake task runs a process that executes the enqueued jobs.

Now, the gory details:

1. A queue adapter allows transparent enqueueing of jobs to GCP Pub/Sub
    - Expectation: write (inspiration: [async adapter](https://github.com/rails/rails/blob/v6.1.4/activejob/lib/active_job/queue_adapters/async_adapter.rb)) and [register](https://guides.rubyonrails.org/v6.1/active_job_basics.html#setting-the-backend) your own ActiveJob queue adapter
2. A background process dequeues and executes pending jobs
    - Expectation: write a simple rake task that can be run from the command line, and which [pulls messages from GCP Pub/Sub](https://googleapis.dev/ruby/google-cloud-pubsub/latest/index.html#receiving-messages) and executes the corresponding job.
3. If a job fails, it should be retried at most two times at least five minutes apart. If the final retry fails, enqueue the job to a morgue queue.
    - Expectation: make sure you support what ActiveJob [already offers](https://api.rubyonrails.org/v6.1.4/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on). This requires very little additional code.
    - Expectation: write down if your approach leads to at least once, exactly once or at most once message semantics.
4. Create some load! Randomly enqueue at least five jobs per seconds, that either fail or take between 0-5 seconds to execute.

The goal of this challenge is to assess your problem solving skills when faced with a problem spanning multiple components and systems (Rails + ActiveJob + Google Pub/Sub). If you get stuck, feel free to ask us for advice.

You *don't* have to extract anything to a separate library or gem. All code can go in a single app.

Why this task? At Kisi we use a custom job processor built on top of Google Pub/Sub which processes many millions of jobs every week. This allows us to do a fair review and give good feedback - it's not a synthetic test task. :)

Good luck! 🙌

## References

- [GCP Pub/Sub][gcp-pubsub]
- [GCP Pub/Sub API][gcp-pubsub-api]
- [ActiveJob Basics][activejob-basics]
- [ActiveJob API][activejob-api]

[gcp-pubsub]: https://cloud.google.com/pubsub
[gcp-pubsub-api]: https://googleapis.dev/ruby/google-cloud-pubsub/latest/index.html
[activejob-basics]: https://guides.rubyonrails.org/v6.1/active_job_basics.html
[activejob-api]: https://api.rubyonrails.org/v6.1.4/classes/ActiveJob/Base.html
