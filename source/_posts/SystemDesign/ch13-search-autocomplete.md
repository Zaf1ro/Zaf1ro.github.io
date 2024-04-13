---
title: System Design - Search Autocomplete
category:
  - System Design
tag:
  - System Design
abbrlink: 6c1f
date: 2024-04-19 12:42:10
keywords:
description:
---

## Step 1 - Understand the problem and establish design scope
* the matching only supported at the beginning of a search query
* system should return 5 autocomplete suggestions
* How does the system know which 5 suggestions to return: determined by popularity, decided by the historical query frequency
* Does the system support spell check?: spell check or autocorrect is not supported
* Are search queries in English?: Yes
* Do we allow capitalization and special characters?: No, we assume all search queries have lowercase alphabetic characters
* How many users use the product?: 10 million DAU

Summary of the requirements:
* Fast response time: autocomplete suggestions must show up fast enough
* Relevant: Autocomplete suggestions should be relevant to the search term
* Sorted: Results returned by the system must be sorted by popularity or other ranking models
* Scalable: The system can handle high traffic volume
* Highly available: The system should remain available and accessible when part of the system is offline, slows down, or experiences unexpected network errors

### Back of the envelope estimation
* Assume 10 million daily active users (DAU)
* An average person performs 10 searches per day
* 20 bytes of data per query string:
    * Assume we use ASCII character encoding. 1 character = 1 byte
    * Assume a query contains 4 words, and each word contains 5 characters on average
    * 4 x 5 = 20 bytes per query
* For every character entered into the search box, a client sends a request to the backend for autocomplete suggestions. On average, 20 requests are sent for each search query.
* ~24,000 query per second (QPS) = 10,000,000 users * 10 queries / day * 20 characters / 24 hours / 3600 seconds
* Peak QPS = QPS * 2 = ~48,000
* Assume 20% of the daily queries are new. 10 million * 10 queries / day * 20 byte per query * 20% = 0.4 GB. This means 0.4GB of new data is added to storage daily.


## Step 2 - Propose high-level design and get buy-in
the system is broken down into two:
* Data gathering service: gather user input queries and aggregates them in real-time.
* Query service: Given a search query or prefix, return 5 most frequently searched terms.

### Data gathering service
Assume we have a frequency table that stores the query string(column 1) and its frequency(column 2).  In the beginning, the frequency table is empty. users enter queries, the frequency table is updated.

### Query service
The frequency table has two fields:
* Query: it stores the query string
* Frequency: it represents the number of times a query has been searched

To get top 5 frequently searched queries, execute the following SQL query:
```sql
SELECT * FROM frequency_table
WHERE query like `prefix%`
ORDER BY frequency DESC
LIMIT 5
```


## Step 3 - Design deep dive
### Trie data structure
The data structure trie (prefix tree) is used to overcome the problem.:
* A trie is a tree-like data structure
* The root represents an empty string
* Each node stores a character and has 26 children
* Each tree node represents a single word or a prefix string

To support sorting by frequency, frequency info needs to be included in nodes, Assume:
* p: length of a prefix
* n: total number of nodes in a trie
* c: number of children of a given node

Steps to get top k most searched queries:
1. Find the prefix. Time complexity: O(p)
2. Traverse the subtree from the prefix node to get all valid children. Time complexity: O(c)
3. Sort the children and get top k. Time complexity: O(clogc)

Two optimizations:
* Limit the max length of a prefix: Users rarely type a long search query into the search box, so we can limit the length of a prefix
* Cache top search queries at each node: store top k most frequently used queries at each node

### Data gathering service
Updating data in real-time is not practical for the following two reasons:
* Users may enter billions of queries per day
* Top suggestions may not change much once the trie is built

For different use cases:
* Twitter: requires up to date autocomplete suggestions.
* Google: keywords might not change much on a daily basis.

The underlying foundation for data gathering service is same: data used to build the trie is from analytics or logging services:
* Analytics Logs: store raw data about search queries. Logs are append-only and are not indexed
* Aggregators: The size of logs is very large, and data is not in the right format, we need to aggregate data so it can be processed by our system
    * For real-time application: aggregate data in a shorter time interval
    * For non-real-time application: aggregating data less frequently, for example, once per week
* Aggregated Data: an example of aggregated weekly data
    * time field: the start time of a week
    * frequency field: the sum of the occurrences for the corresponding query in this week
    * Workers: a set of servers that build the trie data structure and store it in Trie DB
    * Trie Cache: a distributed cache system that keeps trie in memory for fast read
    * Trie DB: the persistent storage, two options:
        * Document store: Since a new trie is built weekly, we can periodically take a snapshot of it, serialize it, and store the serialized data in the database, like MongoDB
        * Key-value store: A trie can be represented in a hash table form, prefix as key, data(top 5 of query and its frequency) as value.

### Query service
1. A search query is sent to the load balancer
2. The load balancer routes the request to API servers
3. API servers get trie data from Trie Cache and construct autocomplete suggestions for the client
4. If the data is not in Trie Cache, replenish data back to the cache

optimizations for speeding the query:
* AJAX request: sending/receiving a request/response does not refresh the whole web page
* Browser caching: save autocomplete suggestions in browser cache
* Data sampling: For a large-scale system, logging every search query requires a lot of processing power and storage. only 1 out of every N requests is logged by the system.

### Trie operations
* Create: Trie is created by workers using aggregated data. The source of data is from analytics Log
* Update: two ways to update the trie
    * Update the trie weekly. Once a new trie is created, the new trie replaces the old one
    * Update individual trie node directly. When we update a trie node, its ancestors all the way up to the root must be updated because ancestors store top queries of children
* Delete: To remove hateful, violent, sexually explicit, or dangerous autocomplete suggestions, we can add a filter layer in front of the Trie Cache

### Scale the storage
shard based on the first character, examples:
* If we have two servers, store queries starting with 'a' to 'm' on the first server, and 'n' to 'z' on the second server
* If we have three servers, split queries into 'a' to 'i', 'j' to 'r' and 's' to 'z'

we can split queries up to 26 servers because there are 26 alphabetic characters in English. But the word is not even distribution by its first character. So we need to analyze historical data distribution pattern and apply smarter sharding logic.


## Step 4 - Wrap up
follow up questions:
* How do you extend your design to support multiple languages?: store Unicode characters in trie nodes
* What if top search queries in one country are different from others?: we might build different tries for different countries
* How can we support the trending (real-time) search queries?: When a news event breaks out, a search query suddenly becomes popular, the original design will not work because the schedule of updating the trie is on weekly basis, and building the trie takes too long. Few ideas:
    * Reduce the working data set by sharding
    * Change the ranking model and assign more weight to recent search queries
    * Keep processing the steam data by other system, like Apache Hadoop MapReduce, Apache Spark Streaming, Apache Kafka

