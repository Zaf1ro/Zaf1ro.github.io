---
title: System Design - Rate Limiter
category:
  - System Design
tag:
  - System Design
abbrlink: a3f6
date: 2024-04-10 12:42:10
keywords:
description:
---


## 1. Introduction
Rate limiter is used to control the rate of traffic sent by a client or a service. A rate limiter limits the number of client requests allowed to be sent over a specified period. If the API request count exceeds the threshold defined by the rate limiter, all the excess calls are blocked.

Benefits of using a rate limiter:
* Prevent resource starvation caused by Denial of Service (DoS) attack
* Reduce cost. Limiting excess requests means fewer servers and allocating more resources to high priority APIs.
* Prevent servers from being overloaded.

## 2. Understand the problem and establish design scope
Rate limiting can be implemented using different algorithms, each with its pros and cons.
* What kind of rate limiter are we going to design? Is it a client-side rate limiter or server-side API rate limiter? -> focus on the server-side API rate limiter
* Does the rate limiter throttle API requests based on IP, the user ID, or other properties? -> The rate limiter should be flexible enough to support different sets of throttle rules.
* What is the scale of the system? Is it built for a startup or a big company with a large user base? -> The system must be able to handle a large number of requests.
* Will the system work in a distributed environment? -> Yes
* Is the rate limiter a separate service or should it be implemented in application code? -> It is a design decision up to you.
* Do we need to inform users who are throttled? -> Yes


## 3. Propose high-level design and get buy-in 
### 3.1 Where to put the rate limiter?
* Client-side: client is an unreliable place to enforce rate limiting because client requests can easily be forged by malicious actors.
* Server-side: place rate limiter at the API servers
    ![Rate Limiter at API Server](/images/System-Design/Interview/4-rate-limiter-at-server.jpg)
* middleware: create a rate limiter middleware, which throttles requests to the API servers
    ![Rate Limiter as Middleware](/images/System-Design/Interview/4-rate-limiter-as-middleware.jpg)

Rate limiting is usually implemented within a component called API gateway. API gateway is a fully managed service that supports rate limiting, SSL termination, authentication, IP whitelisting, servicing static content, etc.

### 3.2 Algorithms for Rate Limiting
List of popular algorithms:
* Token bucket
* Leaking bucket
* Fixed window counter
* Sliding window log
* Sliding window counter

#### 3.2.1 Token Bucket Algorithm
A token bucket is a container that has pre-defined capacity. Tokens are put in the bucket at preset rates periodically. Once the bucket is full, no more tokens are added. Each request consumes one token. When a request arrives, we check if there are enough tokens in the bucket.
![Token Bucket Algorithm](/images/System-Design/Interview/4-token-bucket-algorithm.jpg)

Three components of this algorithm:
* bucket: contains tokens with certain capacity
* refiller: put token into the bucket if bucket is not full
* request: take one token and goes through if bucket is not empty, or dropped

Two important parameters:
* Bucket size: the maximum number of tokens allowed in the bucket
* Refill rate: number of tokens put into the bucket every second

How many buckets do we need:
* different API endpoints have different buckets
* If we need to throttle requests based on IP addresses, each IP address requires a bucket.
* have a global bucket shared by all requests if neccessary

Summary:
* Pros:
    * easy to implement
    * memory efficient
    * allows a burst of traffic for short periods
* Cons: 
    * two parameter may be challenging to tune them properly

#### 3.2.2 Leaking Bucket Algorithm
The algorithm is similar to the token bucket except that requests are processed at a fixed rate. The algorithm works as follows:
* When a request arrives, the system checks if the queue is full. If it is not full, the request is added to the queue.
* Otherwise, the request is dropped.
* Requests are pulled from the queue and processed at regular intervals.

![Leaking Bucket Algorithm](/images/System-Design/Interview/4-leaking-bucket-algorithm.jpg)

Two important parameters:
* Bucket size: it is equal to the queue size. The queue holds the requests to be processed at a fixed rate.
* Outflow rate: it defines how many requests can be processed at a fixed rate, usually in seconds.

Summary:
* Pros:
    * Memory efficient given the limited queue size.
    * Requests are processed at a fixed rate therefore it is suitable for use cases that a stable outflow rate is needed.
* Cons:
    * A burst of traffic fills up the queue with old requests, and if they are not processed in time, recent requests will be rate limited.
    * two parameter may be challenging to tune them properly

#### 3.2.3 Fixed Window Counter Algorithm
The algorithm works as follows:
* The algorithm divides the timeline into fix-sized time windows and assign a counter for each window.
* Each request increments the counter by one.
* Once the counter reaches the pre-defined threshold, new requests are dropped until a new time window starts.

Summary:
* Pros:
    * Memory efficient
    * Resetting available quota at the end of a unit time window fits certain use cases
* Cons:
    * Spike in traffic at the edges of a window could cause more requests than the allowed quota to go through.
    ![Fixed Window Counter Algorithm Issue](/images/System-Design/Interview/4-fixed-window-counter-algorithm-problem.jpg)

#### 3.2.4 Sliding Window Log Algorithm
The algorithm works as follows:
* keeps track of request timestamps. Timestamp data is usually kept in cache, such as sorted sets of Redis
* When a new request comes in, remove all the outdated timestamps. Outdated timestamps are defined as those older than the start of the current time window.
* Add timestamp of the new request to the log.
* If the log size is the same or lower than the allowed count, a request is accepted. Otherwise, it is rejected.

![Sliding Window Log Algorithm Example](/images/System-Design/Interview/4-sliding-window-log-algorithm-example.jpg)

In this example, the rate limiter allows 2 requests per minute:
* The log is empty when a new request arrives at `1:00:01`. Thus, the request is allowed.
* A new request arrives at `1:00:30`, the timestamp `1:00:30` is inserted into the log. After the insertion, the log size is 2, not larger than the allowed count. Thus, the request is allowed.
* A new request arrives at `1:00:50`, and the timestamp is inserted into the log. After the insertion, the log size is 3, larger than the allowed size 2. Therefore, this request is rejected even though the timestamp remains in the log.
* A new request arrives at `1:01:40`. Requests in the range `[1:00:40,1:01:40)` are within the latest time frame, but requests sent before `1:00:40` are outdated. Two outdated timestamps, `1:00:01` and `1:00:30`, are removed from the log. After the remove operation, the log size becomes 2; therefore, the request is accepted.

Summary:
* Pros: 
    * Rate limiting implemented by this algorithm is more accurate than fixed window counter algorithm 
* Cons:
    * The algorithm consumes a lot of memory because even if a request is rejected, its timestamp might still be stored in memory

#### 3.2.5 Sliding window counter algorithm
a hybrid approach that combines the fixed window counter and sliding window log. Assume the rate limiter allows a maximum of **7 requests per minute**, and there are **5 requests** in the **previous minute** and **3** in the **current minute**. For a new request that arrives at a 30% position in the current minute, the number of requests in the rolling window is calculated using the following formula:
Requests in current window + requests in the previous window * overlap percentage of the rolling window and previous window -> 3 + 5 * 0.7 = 6.5 requests. 

![Sliding Window Counter Algorithm](/images/System-Design/Interview/4-sliding-window-counter.jpg)

Summary:
* Pros:
    * It smooths out spikes in traffic because the rate is based on the average rate of the  previous window
    * Memory efficient
* Cons:
    * It only works for not-so-strict look back window, but only 0.003% of requests are wrongly allowed or rate limited

#### 3.2.6 High-level architecture
Where to store counters: Using the database is not a good idea due to slowness of disk access. In-memory cache(Redis) is chosen because it is fast and supports time-based expiration strategy.
For instance, Redis is a popular option to implement rate limiting. It is an in-memory store that offers two commands: `INCR` and `EXPIRE`.
* INCR: It increases the stored counter by 1.
* EXPIRE: It sets a timeout for the counter. If the timeout expires, the counter is automatically deleted.

![Redis as Rate Limiter Data Store](/images/System-Design/Interview/4-redis-as-rate-limiter-data-store.jpg)

* The client sends a request to rate limiting middleware
* Rate limiting middleware fetches the counter from the corresponding bucket in Redis and checks if the limit is reached or not.
    * If the limit is reached, the request is rejected.
    * If the limit is not reached, the request is sent to API servers. Meanwhile, the system increments the counter and saves it back to Redis.


## 4. Design Deep Dive
### 4.1 Rate Limiting Rules
Rules are written in configuration files and saved on disk.
```
domain: auth
descriptors:
  - key: auth_type
    Value: login
    rate_limit:
        unit: minute
        requests_per_unit: 5
```

### 4.2 Exceeding the Rate Limit
APIs return a HTTP response code 429 (too many requests) to the client. Depending on the use cases, we may enqueue the rate-limited requests to be processed later.

Rate limiter should return the following information:
* how many calls the client can make per time window
* The number of seconds to wait until you can send the next request

### 4.3 Detailed Design
![Rate Limiter Detailed Design](/images/System-Design/Interview/4-rate-limiter-detailed-design.jpg)

* Workers frequently pull rules from the disk and store them in the cache.
* When a client sends a request to the server, the request is sent to the rate limiter middleware first
* Rate limiter loads the rule from the cache, fetches counter and last request timestamp from Redis. Based on the response, the rate limiter decides:
    * the request is not rate limited, it is forwarded to API servers
    * the request is rate limited, returns 429 error to the client

### 4.4 Rate limiter in a distributed environment
Building multiple rate limiters in multiple server has two challenges:
* Race condition
    * Example: read and increment the counter in Redis
    * Solution: sorted sets data structure
* Synchronization issue: 
    * Example:
        1. To support millions of users, one rate limiter server is not enough to handle the traffic, different rate limiter has their own Redis cache
        2. client can send requests to any rate limiter
        3. If client 1 sends request to rate limiter 1, then sends request to rate limiter 2. Since rate limiter 2 does not contain any data about client 1. Thus, the rate limiter cannot work properly
    * Solutions:
        * sticky session: one client can only send request to the certain rate limiter
        * centralized data store: all rate limiter only use one Redis

### 4.5 Performance Optimization
* Multi-data center setup. Most cloud service providers build many edge server locations around the world
* Synchronize data with an eventual consistency model.
