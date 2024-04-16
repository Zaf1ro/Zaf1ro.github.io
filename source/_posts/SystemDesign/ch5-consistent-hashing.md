---
title: System Design - Consistent Hashing
category:
  - System Design
tag:
  - System Design
abbrlink: 10a4
date: 2024-04-11 12:42:10
keywords:
description:
---

## 1. The rehashing problem
If you have n cache servers, a common way to balance the load is to use the following hash method: `serverIndex = hash(key) % N`, where `N` is the size of the server pool.
This approach works well when the size of the server pool is fixed. However, problems arise when new servers are added, or existing servers are removed: client will connect to the wrong server to fetch data.


## 2. Consistent hashing
Comparsion:
* Traditional hashing: when making change on the number of slots, all keys need to be remapped
* Consistent hashing: when making change on the number of slots, only `k/n` need to be remapped (`k` is the number of keys, `n` is the number of slots)

### 2.1 Hash space and hash ring
Assume hash function is `f`, and the output range of the hash function is: `$x_0, x_1, x_2, x_3, ..., x_n$`. For example, SHA-1's hash space is `$[0, 2^{160} - 1]$`, `$x_0$` corresponds to `0`, `$x_n$` corresponds to `$2^{160} - 1$`.
![Hash Space](/images/System-Design/Interview/5-hash-space.jpg)

By connecting the `$x_0$` and `$x_n$`, we got a hash ring.
![Hash Ring](/images/System-Design/Interview/5-hash-ring.jpg)

### 2.2 Hash servers
We map the servers based on their IP address or name onto the ring using hash function `f`.
![Hash Server](/images/System-Design/Interview/5-hash-server.jpg)

### 2.3 Hash keys
The cache keys(key0, key1, key2, and key3) are also hashed onto the hash ring, and there is no modular operation
![Hash Keys](/images/System-Design/Interview/5-hash-keys.jpg)

### 2.4 Server lookup
To determine which server a key is stored on, we go clockwise from the key position on the ring until a server is found. For example:
* key0 is stored on server 0
* key1 is stored on server 1
* key2 is stored on server 2
* key3 is stored on server 3.

![Server Lookup](/images/System-Design/Interview/5-server-lookup.jpg)

### 2.5 Add a server
adding a new server will only need to redistribute part of keys. For example, after server 4 is added, only key0 needs to be redistributed; The rest of the keys are unaffected.
![Add New Server](/images/System-Design/Interview/5-add-new-server.jpg)

### 2.6 Remove a server
When a server is removed, only part of keys require redistribution with consistent hashing. For example, when server 1 is removed, only key1 needs to be remapped to server 2. The rest of the keys are unaffected.
![Remove a Server](/images/System-Design/Interview/5-remove-a-server.jpg)


## 3. Two issue in the basic approach
Basic approach of consistent hashing algorithm:
* Map servers and keys on to the ring using a uniformly distributed hash function
* To find out which server a key is mapped to, go clockwise from the key position until the first server on the ring is found

Two problems with the basic approach:
* When add or remove a server, its impossible to keep the same size of partition for each server
* It is possible to have a non-uniform key distribution on the ring  

### 3.1 Virtual nodes
A virtual node refers to the real node, and each server is represented by multiple virtual nodes on the ring. To find which server a key is stored on, we go clockwise from the key's location and find the first virtual node encountered on the ring.
For example, both server 0 and server 1 have 3 virtual nodes:
* server 0: s0_0, s0_1, and s0_2
* server 1: s1_0, s1_1, and s1_2 

![Virtual Nodes Example](/images/System-Design/Interview/5-virtual-nodes-example.jpg)

As the number of virtual nodes increases, the distribution of keys becomes more balanced; However, more spaces are needed to store data about virtual nodes. This is a tradeoff, and we can tune the number of virtual nodes to fit our system requirements.

### 3.2 Find affected keys
* Add new server: when server `S` is added onto the ring. The affected range starts from `S` and moves anticlockwise around the ring until a server is found `S'`. Thus, keys located between `S'` and `S` need to be redistributed to `S`. For example, server 4 is added onto the ring, keys located between s3 and s4 need to be redistributed to s4.
  ![Add New Server with Virtual Nodes](/images/System-Design/Interview/5-virtual-nodes-add-server.jpg)


* Remove existing server: the affected range starts from `S`(removed node) and moves anticlockwise around the ring until a server is found `S'`. Thus, keys located between `S` and `S'` must be redistributed to `S'`. For example, When a server 1 is removed, the affected range is between server 0 and server 1.
  ![Remove Server with Virtual Nodes](/images/System-Design/Interview/5-virtual-nodes-remove-server.jpg)


## 4. Summary
The benefits of consistent hashing:
* Minimized the number of redistributed keys when servers are added or removed
* Data are more evenly distributed, so it's easy to scale horizontally
* Mitigate hotspot key problem. Excessive access to a specific shard could cause server overload

Consistent hashing use case:
* Partitioning component of Amazon's Dynamo database
* Data partitioning across the cluster in Apache Cassandra
* Discord chat application
* Akamai content delivery network
* Maglev network load balancer 


