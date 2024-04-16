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

## 1. Understand the problem and establish design scope
* Is the matching only supported at the beginning of a search query or in the middle as well the matching only supported at the beginning of a search query:  Only at the beginning of a search query
* How many autocomplete suggestions should the system return: 5
* How does the system know which 5 suggestions to return: determined by popularity, decided by the historical query frequency
* Does the system support spell check: No, spell check or autocorrect is not supported
* Are search queries in English: Yes
* Do we allow capitalization and special characters: No, we assume all search queries have lowercase alphabetic characters
* How many users use the product?: 10 million DAU

Requirements:
* Fast response time: autocomplete suggestions must show up fast enough
* Relevant: Autocomplete suggestions should be relevant to the search term
* Sorted: Results returned by the system must be sorted by popularity or other ranking models
* Scalable: The system can handle high traffic volume
* Highly available: The system should remain available and accessible when part of the system is offline, slows down, or experiences unexpected network errors

### 1.1 Back of the envelope estimation
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


## 2. Propose high-level design and get buy-in
The system is broken down into two:
* Data gathering service: gather user input queries and aggregates them in real-time
* Query service: Given a search query or prefix, return 5 most frequently searched terms

### 2.1 Data gathering service
Assume we have a frequency table that stores the **query string** and its **frequency**.  In the beginning, the frequency table is empty. Later, users enter queries "twitch", "twitter", "twitter," and "twillo" sequentially.
![Data Gathering](/images/System-Design/Interview/13-data-gathering.jpg)

### 2.2 Query service
Assume we have a frequency table, and it has two fields:
![Frequency Table](/images/System-Design/Interview/13-frequency-table.jpg)

* Query: it stores the query string
* Frequency: it represents the number of times a query has been searched

To get top 5 frequently searched queries, execute the following SQL query:
```sql
SELECT * FROM frequency_table
WHERE query like `prefix%`
ORDER BY frequency DESC
LIMIT 5
```
This is an acceptable solution when the data set is small. When it is large, accessing the database becomes a bottleneck.

## 3. Design deep dive
### 3.1 Trie data structure
Relational databases are used for storage in the high-level design. However, fetching the top 5 search queries from a relational database is inefficient. The data structure trie (prefix tree) is used to overcome the problem:
* A trie is a tree-like data structure
* The root represents an empty string
* Each node stores a character and has 26 children
* Each tree node represents a single word or a prefix string

![Trie Example](/images/System-Design/Interview/13-trie-example.jpg)

To support sorting by frequency, frequency info needs to be included in nodes.
![Updated Trie Example](/images/System-Design/Interview/13-updated-trie-example.jpg)

Before diving into the algorithm, let us define some terms:
* p: length of a prefix
* n: total number of nodes in a trie
* c: number of children of a given node

Steps to get top k most searched queries:
1. Find the prefix. Time complexity: `O(p)`
2. Traverse the subtree from the prefix node to get all valid children. Time complexity: `O(c)`
3. Sort the children and get top k. Time complexity: `O(clogc)`

The time complexity of this algorithm is the sum of time spent on each step mentioned above: `O(p) + O(c) + O(clogc)`. It's too slow because we need to traverse the entire trie to get top k results in the worst-case scenario. Below are two optimizations:
* Limit the max length of a prefix: Users rarely type a long search query into the search box, so we can limit the length of a prefix
* Cache top search queries at each node: store top k most frequently used queries at each node

![Optimized Trie Example](/images/System-Design/Interview/13-optimized-trie-example.jpg)

* Find the prefix node. Time complexity: O(1)
* Return top k. Since top k queries are cached, the time complexity for this step is O(1).

### 3.2 Data gathering service
Updating data in real-time may be not practical for the following two reasons:
* Users may enter billions of queries per day
* Top suggestions may not change much once the trie is built

For different use cases:
* Twitter: requires up to date autocomplete suggestions.
* Google: keywords might not change much on a daily basis.

Despite the differences in use cases, the underlying foundation for data gathering service is same because data used to build the trie is from analytics or logging services.
![Redesigned Data Gathering Service](/images/System-Design/Interview/13-redesigned-data-gathering-service.jpg)

* Analytics Logs: store raw data about search queries. Logs are append-only and are not indexed
* Aggregators: The size of logs is very large, and data is not in the right format. We need to aggregate data so it can be processed by our system
    * For real-time application: aggregate data in a shorter time interval
    * For non-real-time application: aggregate data less frequently, for example, once per week
* Aggregated Data:
    ![Aggregated Data](/images/System-Design/Interview/13-aggregated-data.jpg)
    * Time field: the start time of a week
    * Frequency field: the sum of the occurrences for the corresponding query in this week
    * Workers: a set of servers that build the trie data structure and store it in Trie DB
    * Trie Cache: a distributed cache system that keeps trie in memory for fast read
    * Trie DB: the persistent storage, two options:
        * Document store: Since a new trie is built weekly, we can periodically take a snapshot of it, serialize it, and store the serialized data in the database, like MongoDB
        * Key-value store: A trie can be represented in a hash table form, prefix as key, data(top 5 of query and its frequency) as value.

![Mapping between trie and key-value store](/images/System-Design/Interview/13-mapping-between-trie-and-key-value-store.jpg)

### 3.3 Query service
![Mapping between trie and key-value store](/images/System-Design/Interview/13-query-service.jpg)

1. A search query is sent to the load balancer
2. The load balancer routes the request to API servers
3. API servers get trie data from Trie Cache and construct autocomplete suggestions for the client
4. If the data is not in Trie Cache, we replenish data back to the cache

Optimizations for speeding the query:
* AJAX request: sending/receiving a request/response does not refresh the whole web page
* Browser caching: For many applications, autocomplete search suggestions may not change much within a short time. Thus, autocomplete suggestions can be saved in browser cache to allow subsequent requests to get results from the cache directly.
* Data sampling: For a large-scale system, logging every search query requires a lot of processing power and storage. Only 1 out of every N requests will be logged by the system.

### 3.4 Trie operations
#### 3.4.1 Create
Trie is created by workers using aggregated data. The source of data is from Analytics Log/DB

#### 3.4.2 Update: two ways to update the trie:
* Update the trie weekly. Once a new trie is created, the new trie replaces the old one
* Update individual trie node directly. When we update a trie node, its ancestors all the way up to the root must be updated because ancestors store top queries of children

![Update Trie Node](/images/System-Design/Interview/13-update-trie-node.jpg)
On the left side, the search query "beer" has the original value 10. On the right side, it is updated to 30. As you can see, the node and its ancestors have the "beer" value updated to 30.

#### 3.4.3 Delete
To remove hateful, violent, sexually explicit, or dangerous autocomplete suggestions, we can add a filter layer in front of the Trie Cache

### 3.5 Scale the storage
Since English is the only supported language, a naive way to shard is based on the first character. Here are some examples:
* If we have two servers, store queries starting with `'a'` to `'m'` on the first server, and `'n'` to `'z'` on the second server
* If we have three servers, split queries into `'a'` to `'i'`, `'j'` to `'r'` and `'s'` to `'z'`

We can split queries up to 26 servers because there are 26 alphabetic characters in English. But the word is not even distribution by its first character. So we need to analyze historical data distribution pattern and apply smarter sharding logic.


## 4. Wrap up
Follow up questions:
* How to support multiple languages: store Unicode characters in trie nodes
* What if top search queries in one country are different from others: we might build different tries for different countries
* How can we support the trending (real-time) search queries: When a news event breaks out, a search query suddenly becomes popular, the original design will not work because the schedule of updating the trie is on weekly basis, and building the trie takes too long. Few ideas:
    * Reduce the working data set by sharding
    * Change the ranking model and assign more weight to recent search queries
    * Data may come as streams, so we do not have access to all the data at once. Stream processing requires a different set of systems: Apache Hadoop MapReduce, Apache Spark Streaming, Apache Kafka

