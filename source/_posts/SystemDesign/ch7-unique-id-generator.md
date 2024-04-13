---
title: System Design - Unique ID Generator
category:
  - System Design
tag:
  - System Design
abbrlink: b1ee
date: 2024-04-13 12:42:10
keywords:
description:
---

## 1. Introduction
first thought: use a primary key with the `auto_increment` attribute in a traditional database
Drawback: `auto_increment` does not work in a distributed environment


## Step 1: Understand the problem and establish design scope
* What are the characteristics of unique IDs: IDs must be unique and sortable
* For each new record, does ID increment by 1: The ID increments by time but not necessarily only increments by 1
* Do IDs only contain numerical values?: Yes
* What is the ID length requirement?: 64-bit
* What is the scale of the system?: generate 10,000 IDs per second

requirements of system:
* IDs must be unique.
* IDs are numerical values only.
* IDs fit into 64-bit.
* IDs are ordered by date.
* Ability to generate over 10,000 unique IDs per second


## Step 2 - Propose high-level design and get buy-in
Multiple options to generate unique IDs:
* Multi-master replication
* UUID
* Ticket server
* Twitter snowflake approach

### Multi-master replication
This approach uses the `auto_increment` feature. Instead of increasing the next ID by 1, we increase it by `k`, where `k` is the number of database servers in use. 

Drawbacks:
* Hard to scale with multiple data centers
* IDs do not go up with time across multiple servers
*  It does not scale well when a server is added or removed

### UUID
UUID is a 128-bit number used to identify information in computer systems. UUID has a very low probability of getting collision, and can be generated independently without coordination between servers.
Pros:
* simple: No need to coordinate between servers
* easy to scale: each web server is responsible for generating IDs they consume

Cons:
* IDs are 128 bits long, but our requirement is 64 bits
* IDs don't go up with time
* IDs could be non-numeric

### Ticket Server
use a centralized `auto_increment` feature in a single database server
Pros:
* Numeric IDs
* Easy to implement, and works for small to medium-scale applications

Cons:
* Single point of failure

### Twitter snowflake approach
Instead of generating an ID directly, we divide an ID into different sections:
* Sign bit: 1 bit, always be 0, reserved for future uses
* Timestamp: 41 bits, milliseconds since the custom epochs
* Datacenter ID: 5 bits -> 32 datacenters
* Machine ID:  5 bits -> 32 machines per datacenter
* Sequence number: 12 bits -> For every ID generated on that machine, the sequence number is incremented by 1. The number is reset to 0 every millisecond.


## Step 3 - Design deep dive
Datacenter IDs and machine IDs are chosen at the startup time, generally fixed once the system is up running. 
Timestamp and sequence numbers are generated when the ID generator is running.

### Timestamp
An example of how binary representation is converted to UTC: 297616116568(timestamp) + 1288834974657(epoch) = 1586451091225(UTC) -> Apr 09 2020 16:51:31 UTC.
The maximum timestamp that can be represented in 41 bits is `2 ^ 41 - 1 = 2199023255551` milliseconds (ms), about 69 years. After 69 years, we will need a new epoch time or adopt other techniques to migrate IDs.

### Sequence number
Sequence number is 12 bits, which give us `2 ^ 12 = 4096` combinations. It means a machine can support a maximum of 4096 new IDs per millisecond.


## Step 4 - Wrap up
additional talking points:
* Clock synchronization: we assume ID generation servers have the same clock. This assumption might not be true when a server is running on multiple cores -> Network Time Protocol
* Section length tuning: fewer sequence numbers but more timestamp bits are effective for low concurrency and long-term applications

