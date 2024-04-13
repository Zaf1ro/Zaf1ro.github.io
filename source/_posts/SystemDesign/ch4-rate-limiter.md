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


## Introduction
Rate limiter is used to control the rate of traffic sent by a client or a service. A rate limiter limits the number of client requests allowed to be sent over a specified period. If the API request count exceeds the threshold defined by the rate limiter, all the excess calls are blocked.

Benefits of using a rate limiter:
* Prevent resource starvation caused by Denial of Service (DoS) attack
* Reduce cost. Limiting excess requests means fewer servers and allocating more resources to high priority APIs.
* Prevent servers from being overloaded.

## Step 1: Understand the problem and establish design scope
Rate limiting can be implemented using different algorithms, each with its pros and cons. 

1. What kind of rate limiter are we going to design? Is it a client-side rate limiter or server-side API rate limiter? -> focus on the server-side API rate limiter
2. Does the rate limiter throttle API requests based on IP, the user ID, or other properties? -> The rate limiter should be flexible enough to support different sets of throttle rules.
3. What is the scale of the system? Is it built for a startup or a big company with a large user base? -> The system must be able to handle a large number of requests.
4. Will the system work in a distributed environment? -> Yes
5. Is the rate limiter a separate service or should it be implemented in application code? -> It is a design decision up to you.
6. Do we need to inform users who are throttled? -> Yes


## Step 2: Propose high-level design and get buy-in 
### Where to put the rate limiter?
* Client-side: client is an unreliable place to enforce rate limiting because client requests can easily be forged by malicious actors.
* Server-side: place rate limiter at the API servers
* middleware: create a rate limiter middleware, which throttles requests to the API servers

Rate limiting is usually implemented within a component called API gateway. API gateway is a fully managed service that supports rate limiting, SSL termination, authentication, IP whitelisting, servicing static content, etc.

### Algorithms for rate limiting
list of popular algorithms:
* Token bucket
* Leaking bucket
* Fixed window counter
* Sliding window log
* Sliding window counter

#### 1. Token bucket algorithm
A token bucket is a container that has pre-defined capacity. Tokens are put in the bucket at preset rates periodically. Once the bucket is full, no more tokens are added.
Each request consumes one token. When a request arrives, we check if there are enough tokens in the bucket.

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

#### 2. Leaking bucket algorithm
The algorithm works as follows:
* When a request arrives, the system checks if the queue is full. If it is not full, the request is added to the queue.
* Otherwise, the request is dropped.
* Requests are pulled from the queue and processed at regular intervals.

The algorithm is similar to the token bucket except that requests are processed
at a fixed rate.

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

#### 3. Fixed window counter algorithm
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

#### 4. Sliding window log algorithm
The algorithm works as follows:
* keeps track of request timestamps. Timestamp data is usually kept in cache, such as sorted sets of Redis
* When a new request comes in, remove all the outdated timestamps. Outdated timestamps are defined as those older than the start of the current time window.
* Add timestamp of the new request to the log.
*  If the log size is the same or lower than the allowed count, a request is accepted. Otherwise, it is rejected.

Summary:
* Pros: 
    * Rate limiting implemented by this algorithm is more accurate than fixed window counter algorithm 
* Cons:
    * The algorithm consumes a lot of memory because even if a request is rejected, its timestamp might still be stored in memory

#### 5. Sliding window counter algorithm
a hybrid approach that combines the fixed window counter and sliding window log. Assume the rate limiter allows a maximum of **7 requests per minute**, and there are **5 requests** in the **previous minute** and **3** in the **current minute**. For a new request that arrives at a 30% position in the current minute, the number of requests in the rolling window is calculated using the following formula:
Requests in current window + requests in the previous window * overlap percentage of the rolling window and previous window -> 3 + 5 * 0.7 = 6.5 requests. 

Summary:
* Pros:
    * It smooths out spikes in traffic because the rate is based on the average rate of the  previous window
    * Memory efficient
* Cons:
    * It only works for not-so-strict look back window, but only 0.003% of requests are wrongly allowed or rate limited

#### High-level architecture
Where to store counters: Using the database is not a good idea due to slowness of disk access. In-memory cache(Redis) is chosen because it is fast and supports time-based expiration strategy.


## Step 3 - Design deep dive
### Rate limiting rules
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

### Exceeding the rate limit
APIs return a HTTP response code 429 (too many requests) to the client. Depending on the use cases, we may enqueue the rate-limited requests to be processed later.

Rate limiter should return the following information:
* how many calls the client can make per time window
* The number of seconds to wait until you can send the next request

### Detailed Design
* Workers frequently pull rules from the disk and store them in the cache.
* When a client sends a request to the server, the request is sent to the rate limiter middleware first
* Rate limiter loads the rule from the cache, fetches counter and last request timestamp from Redis. Based on the response, the rate limiter decides:
    * the request is not rate limited, it is forwarded to API servers
    * the request is rate limited, returns 429 error to the client

### Rate limiter in a distributed environment
Building multiple rate limiters in multiple server has two challenges:
* Race condition <- read and increment the counter in Redis <- sorted sets data structure
* Synchronization issue <- different rate limiter has their own Redis cache, and client can send request to different rate limiter
    * sticky session: one client can only send request to the certain rate limiter
    * centralized data store: all rate limiter only use one Redis


