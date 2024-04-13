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


## The rehashing problem
If you have n cache servers, a common way to balance the load is to use the following hash method: `serverIndex = hash(key) % N`, where `N` is the size of the server pool.
This approach works well when the size of the server pool is fixed. However, problems arise when new servers are added, or existing servers are removed: client will connect to the wrong server to fetch data.


## Consistent hashing
Comparsion:
* Traditional hashing: when making change on the number of slots, nearly all keys need to be remapped
* Consistent hashing: when making change on the number of slots, only `k/n` need to be remapped (k is the number of keys, n is the number of slots)

### Hash space and hash ring
Assume SHA-1 is used as the hash function `f`, and the output range of the hash function is: `x0, x1, x2, x3, ..., xn`. Since SHA-1's hash space is `[0, 2^160 - 1]`, `x0` corresponds to 0, `xn` corresponds to `2^160 - 1`. By connecting the x0 and xn, we got a hash ring.

### Hash servers
We map the servers based on their IP address or name onto the ring using hash function `f`. 

### Hash keys
The cache keys are also hashed onto the hash ring.

### Server lookup
To determine which server a key is stored on, we go clockwise from the key position on the ring until a server is found. 

### Add a server
adding a new server will only need to redistribute part of keys. 

### Remove a server
When a server is removed, only part of keys require redistribution with consistent hashing


## Two issue in the basic approach
basic approach:
* Map servers and keys on to the ring using a uniformly distributed hash function
* To find out which server a key is mapped to, go clockwise from the key position until the first server on the ring is found

Two problems:
* when add or remove a server, its impossible to keep the same size of partition for each server
* it is possible to have a non-uniform key distribution on the ring  

### Virtual nodes
each server is represented by multiple virtual nodes on the ring, and each server is responsible for multiple partitions. To find which server a key is stored on, we go clockwise from the key’s location and find the first virtual node encountered on the ring.
As the number of virtual nodes increases, the distribution of keys becomes more balanced; However, more spaces are needed to store data about virtual nodes. This is a tradeoff, and we can tune the number of virtual nodes to fit our system requirements.

### Find affected keys
* Add new server: when server `S` is added onto the ring. The affected range starts from `S`(newly added node) and moves anticlockwise around the ring until a server is found `S'`. Thus, keys located between `S'` and `S` need to be redistributed to `S`.
* Remove existing server: the affected range starts from `S`(removed node) and moves anticlockwise around the ring until a server is found `S'`. Thus, keys located between `S` and `S'` must be redistributed to `S'`.


## Summary
The benefits of consistent hashing:
* Minimized the number of redistributed keys when servers are added or removed
* Data are more evenly distributed, so it's easy to scale horizontally
* Mitigate hotspot key problem. Excessive access to a specific shard could cause server overload



