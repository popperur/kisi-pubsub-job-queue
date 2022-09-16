# The Kisi Backend Code Challenge

This project is my solution for the [Kisi Backend Code Challenge](https://gist.github.com/ce07c3/59fad76f82b39c6b9d3728f4333379ca) .

The project contains a simple background job system that is compatible with the ActiveJob interface of Rails and 
allows Rails developers to easily enqueue jobs to a Google Pub/Sub backend. Additionally, a rake task runs a process 
that executes the enqueued jobs. Both the enqueue and the process happens on a specific `queue`. 
A queue is represented by a `Topic`-`Subscription` pair with the same name in the Pub/Sub system. If none exists, 
the engine will automatically create both the `Topic` and `Subscription` objects.  

Pass the `PUBSUB_JOB_QUEUE_PROJECT_ID` variable to set the id of the Pub/Sub project holding `Topics` 
and `Subscriptions` for the job queues. Make sure that both the `web` and `worker` docker services get the same value.
If not defined, `job_queue` will be set as a project id.

Pass the `QUEUE_NAME` variable to set the name of the job queue for a new worker. If not defined, 
the queue name will be set to "default".


To start all services, make sure you have [Docker](https://www.docker.com/products/docker-desktop/) installed and run:
```
$ docker compose up
```

To test the background job system, open a rails console and enqueue `MockJob` jobs:
```
$ docker compose exec web rails console
> MockJob.perform_later(sleep_duration: 3, raise_error: true)
```
The example above will start a job that sleeps 3 seconds, then raises a `JobError`. 
There is `retry_on` configured on this error, so the ActiveJob system will re-enqueue the job 2 more times, 
five minutes apart. You can change this configuration in the `ApplicationJob` class.


You can use a job spawner service to quickly enqueue a number of jobs:
```
$ docker compose exec web rails console
> Pubsub::Job::Spawner.call(job_count: 10)
```

The example above will enqueue 10 `MockJob` jobs where both the `sleep_duration` and the `raise_error` 
values are randomized.

You can remove all pending jobs from a queue with the `worker:clear` task:
```
$ docker compose exec web rake worker:clear
```

To execute the test suite, run:
```
$ docker compose run --rm web rails test
```

If you run docker with a VM (e.g. Docker Desktop for Mac), it is recommended to allocate at least 2GB Memory.
