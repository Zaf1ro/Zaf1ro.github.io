---
title: System Design - Key Value Store
category:
  - System Design
tag:
  - System Design
abbrlink: 9f9c
date: 2024-04-12 12:42:10
keywords:
description:
---

## Introduction
In key-value store(or key-value database), Each unique identifier is stored as a key with its associated value. This data pairing is known as a "key-value" pair.

In a key-value pair, the key must be unique, and the value associated with the key can be accessed through the key. The value can be strings, lists, objects.

Here's some characteristics of key-value store:
* The size of a key-value pair is small
* Ability to store big data.
* High availability: The system responds quickly, even during failures.
* High scalability
* Automatic scaling
* Tunable consistency
* Low latency


## Single server key-value store
The easist approach: store key-value pair in a hash table
Two optimizations:
* Data compression
* Store only frequently used data in memeory and rest on disk


## Distributed key-value store
### CAP theorem
it is impossible for a distributed system to guarantee all of three guarantees:
* Consistency: all clients see the same data at the same time no matter which node they connect to
* Availability: request sent from client always gets a response even if some of the nodes are down
* Partition Tolerance: the system continues to operate despite network partitions

* CP system: supports consistency and partition tolerance, sacrifice availability
* AP system: supports availability and partition tolerance, sacrifice consistency
* CA system: supports consistency and availability, sacrifice partition tolerance

Since network failure is unavoidable, a distributed system must tolerate network partition. Thus, a CA system cannot exist in realworld applications.

### Real-world distributed systems
Since network partition cannot be avoided, we must choose between consistency and availability. Assume we have 3 servers(s1, s2, s3) in a distributed system, and s3 goes down:
* choose consistency: block all write operation to s1 and s2 to avoid data consistency
* choose availability: keep accepting read even it returns old data. s1 and s2 keep accepting writes, and synced to s3 when network partition is resolved

### System components
#### Data partition
split the data into smaller partitions and store them in multiple servers.
Two challenges:
* Distribute data across multiple servers evenly
* Minimize data movement when nodes are added or removed

Solution: Consistent hashing
advantages: Automatic scaling, heterogenrity

#### Data replication
replicate data asynchronously over N servers: after a key is mapped to a position on the hash ring, walk clockwise from that position and choose the first N servers on the ring.
With virtual nodes, the first N nodes on the ring may be owned by fewer than N physical servers. To avoid this issue, we only choose unique servers while performing the clockwise walk logic.
Nodes in the same data center often fail at the same time: replicas should be placed in distinct data centers.

#### Consistency
Quorum consensus can guarantee consistency for both read and write operations
* N: The number of replicas
* W: A write quorum. For a successful write operation, write operation must be acknowledged from W replicas.
* R: A read quorum. For a successful read operation, read operation must wait for responses from at least R replicas.

W = 1: data is replicated at s0, s1, s2. the coordinator must receive at least one acknowledgment before the write operation is considered as successful. A coordinator acts as a proxy between the client and the nodes.

The configuration of W, R and N is a typical tradeoff between latency and consistency:
* W or R = 1: the query is quick but with bad consistency
* W or R > 1: the query will be slower but with better consistency
* W + R > N: strong consistency is guaranteed <- at least one overlapping node that has the latest data to ensure consistency
* R = 1 and W = N: the system is optimized for a fast read

##### Consistency models
* Strong consistency: any read operation returns the most updated write data item. A client never sees out-of-date data. -> not to accept new reads/writes until every replica has agreed on current write
* Weak consistency: read operations may not see the most updated value.
* Eventual consistency: Given enough time, all updates are propagated, and all replicas are consistent.

##### Inconsistency resolution: versioning
Replication:
* pros: high availability
* cons: inconsistencies among replicas

Solution for inconsistencies: versioning and vector locks. Versioning means treating each data modification as a new immutable version of data. 
Assume we have two servers(s1 and s2), and each server has a replica(key-value pair): `name: john`. s1 changes the name to `johnSanFrancisco` and s2 changes the name to `johnNewYork`. These two changes are performed simultaneously. Now, we have conflicting values, called versions v1 and v2.

To resolve the conflict of the last two versions, we need a versioning system that can detect conflicts and reconcile conflicts -> vector clock
A vector clock is a `[server, version]` pair associated with a data item. It can be used to check if one version precedes, succeeds, or in conflict with others. Assume a vector clock is represented by `D([S1, v1], [S2, v2], …, [Sn, vn])`:
* `D`: a data item
* `v1`: a version counter
* `s1`: a server number

If data item `D` is written to server `Si`, the system must perform one of the following tasks:
* Increment `vi` if `[Si, vi]` exists
* Otherwise, create a new entry `[Si, 1]`

Example:
1. client writes `D1` to the system: the write is handled by server `Sx`, and `Sx` creates a vector clock `D1[(Sx, 1)]`.
2. Another client reads the latest `D1`, updates it to `D2`, and writes it back. Assume the write is handled by the same server `Sx`, which now has vector clock `D2([Sx, 2])`.
3. Another client reads the latest `D2`, updates it to `D3`, and writes it back. Assume the write is handled by server `Sy`, which now has vector clock `D3([Sx, 2], [Sy, 1])`.
4. Another client reads the latest `D2`, updates it to `D4`, and writes it back. Assume the write is handled by server `Sz`, which now has `D4([Sx, 2], [Sz, 1])`.
5. When another client reads `D3` and `D4`, it discovers a conflict, which is caused by data item D2 being modified by both `Sy` and `Sz`.  The conflict is resolved by the client and updated data is sent to the server.

When no conflict: X is an ancestor of Y if the version counters of Y is greater than or equal to the ones in X. For example: the vector clock `D([s0, 1], [s1, 1])` is an  ancestor of `D([s0, 1], [s1, 2])`.
When conflict exists: X is a sibling of Y if there is any participant in Y's vector clock who has a counter that is less than its corresponding counter in X. For example, `D([s0, 1], [s1, 2])` and `D([s0, 2], [s1, 1])`.

Downsides:
* vector clocks add complexity to the client because it needs to implement conflict resolution logic
* the [server: version] pairs in the vector clock could grow rapidly -> set a threshold for the length, and if it exceeds the limit, the oldest pairs are removed

#### Handling failures
##### Failure detection
In a distributed system, it's hard to believe to say the other server is down. 
Solution 1: all-to-all multicasting
Drawback: this is inefficient when many servers are in the system

Solution 2: use decentralized failure detection methods like gossip protocol, works as follows:
1. Each node maintains a node membership list, which contains member IDs and heartbeat counters
2. Each node periodically increments its heartbeat counter
3. Each node periodically sends heartbeats to a set of random nodes, which in turn
propagate to another set of nodes
4. Once node receive heartbeats, update membership list to the latest
5. If the heartbeat has not increased for more than predefined periods, the member is considered as offline

For example:
1. Node `s0` maintains a membership list.
2. Node `s0` notices that node `s2`'s heartbeat counter has not increased for a long time.
3. Node `s0` sends heartbeats that include `s2`'s info to a set of random nodes. Once other nodes confirm that `s2`'s heartbeat counter has not been updated for a long time, node `s2` is marked down.

##### Handling temporary failures
After failures have been detected, the system needs to deploy certain mechanisms to ensure availability. In the strict quorum approach, read and write operations could be blocked -> sloppy quorum: Instead of enforcing the quorum requirement, the system chooses the first W healthy servers for writes and first R healthy servers for reads on the hash ring; When the down server is up, changes will be pushed back to achieve data consistency.

##### Handling permanent failures
To handle permanent failure, we have to compare each piece of data on replicas and update each replica to the newest version. A Merkle tree is used for inconsistency detection and minimizing the amount of data transferred.
Steps of building a Merkle tree:
1. Divide `key space` into `buckets` 
2. Hash each `key` in a bucket using a uniform hashing method
3. Create a single hash node per `bucket`
4. Build the tree upwards till root by calculating hashes of children

To compare two Merkle trees:
* start by comparing the root hashes
    * If root hashes match: both servers have the same data
    * If not: compare its left chold and right child

Traverse the tree to find which buckets are not synchronized and synchronize those buckets only.

##### Handling data center outage
It's important to replicate data across multiple data centers to handle data center outage. 


#### System architecture diagram
Main features of the architecture:
* Clients communicate with the key-value store through simple APIs: get(key) and put(key, value).
* A coordinator is a node that acts as a proxy between the client and the key-value store
* Nodes are distributed on a ring using consistent hashing
* The system is decentralized so adding and moving nodes can be automatic
* Data is replicated at multiple nodes
* every node has the same set of responsibilities -> no single point of failure

##### Write path
1. The write request is persisted on a commit log file
2. Data is saved in the memory cache
3. When the memory cache is full or reaches a predefined threshold, data is flushed to SSTable on disk

##### Read path
first checks if data is in the memory cache
* If so, the data is returned to the client
* If not, checks the bloom filter to find out which SSTable contains the key
* SSTables return the result of the data set
* The result of the data set is returned to the client


### Summary
* store big data: use consistent hashing to spread the load across servers
* high available read: data replication, multi-data center
* High available write: versioning and conflict resolution with vector clock
* Dataset partition: consistent hashing
* Incremental scalability: consistent hashing
* Heterogeneity: consistent hashing
* Tunable consistency: Quorum consensus
* temporary failure: sloppy quorum and hinted handoff
* permanent failure: merkle tree
* data center outage: cross-data center replication
