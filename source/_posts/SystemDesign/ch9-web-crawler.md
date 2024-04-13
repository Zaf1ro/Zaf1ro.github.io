---
title: System Design - Web Crawler
category:
  - System Design
tag:
  - System Design
abbrlink: 1f68
date: 2024-04-15 12:42:10
keywords:
description:
---

## Introduction
web crawler is used by search engines to discover new or updated content on the web. A web crawler starts by collecting a few web pages and then follows links on those pages to collect new content.

purposes:
* Search engine indexing
* Web archiving
* Web mining
* Web monitoring


## Step 1 - Understand the problem and establish design scope
basic algorithm of a web crawler:
1. Given a set of URLs, download all the web pages addressed by the URLs
2. Extract URLs from these web pages
3. Add new URLs to the list of URLs to be downloaded

questions:
* main purpose of the crawler: Search engine indexing
* How many web pages does the web crawler collect per month: 1 billion pages
* What content types are included?: HTML only
* Shall we consider newly added or edited web pages?: Yes, both
* Do we need to store HTML pages crawled from the web?: Yes, up to 5 years
* How do we handle web pages with duplicate content?: Pages with duplicate content should be ignored

characteristics of a good web crawler:
* Scalability: Web crawling should be efficient by using parallelization
* Robustness: web crawler should handle bad HTML, unresponsive servers, crashes, malicious links
* Politeness: web crawler should not make too many requests to a website in a short time interval
* Extensibility: minimal changes are needed to support new content types

### Back of the envelope estimation
* Assume 1 billion web pages are downloaded every month.
* QPS: 1,000,000,000 / 30 days / 24 hours / 3600 seconds = 400 pages per second
* Peak QPS = 2 * QPS = 800 pages per second
* Assume the average web page size is 500k
* 1,000,000,000 x 500k = 500 TB storage per month
* 500 TB * 12 months * 5 years = 30 PB for five years


## Step 2 - Propose high-level design and get buy-in
### Seed URLs
A web crawler uses seed URLs as a starting point for the crawl process. A good seed URL serves as a good starting point that a crawler can utilize to traverse as many links as possible. The general strategy is to divide the entire URL space into smaller ones:
* based on locality as different countries may have different popular websites
* based on topics

### URL Frontier
Most modern web crawlers split the crawl state into two:
* to be downloaded
* already downloaded

The component that stores URLs to be downloaded is called the **URL Frontier** -> a First-in-First-out (FIFO) queue

### HTML Downloader
The HTML downloader downloads web pages from the internet. Those URLs are provided by the URL Frontier.

### DNS Resolver
To download a web page, a URL must be translated into an IP address. The HTML Downloader calls the DNS Resolver to get the corresponding IP address for the URL.

### Content Parser
After a web page is downloaded, it must be parsed and validated because malformed web pages could provoke problems and waste storage space.

### Content Seen?
eliminate data redundancy and shorten processing time -> compare the hash values of the two web pages

### Content Storage
storage system for storing HTML content. 
* Most of the content is stored on disk because the data set is too big to fit in memory
* Popular content is kept in memory to reduce latency

### URL Extractor
parse and extract links from HTML pages. Relative paths are converted to absolute URLs by adding website prefix.

### Web crawler workflow
1. Add seed URLs to the URL Frontier
2. HTML Downloader fetches a list of URLs from URL Frontier
3. HTML Downloader gets IP addresses of URLs from DNS resolver and starts downloading
4. Content Parser parses HTML pages and checks if pages are malformed, and passed to the "Content Seen" component
5. "Content Seen" component checks if a HTML page is already in the storage
    * If it is in the storage, the HTML page is discarded
    * If it is not in the storage, passed to Link Extractor
6. Link extractor extracts links from HTML pages, and passed to the "URL Seen" component
7. "URL Seen" component checks if a URL is already in the storage. if yes, it is processed before, and nothing needs to be done.
8. If a URL has not been processed before, added to the URL Frontier


## Step 3 - Design deep dive
### DFS vs BFS
web as a directed graph, web pages serve as nodes and hyperlinks. Web crawl process can be seen as traversing a directed graph from one page to others. DFS is usually not a good choice because the depth of DFS can be very deep.
BFS is commonly used by web crawlers and is implemented by a first-in-first-out(FIFO) queue. This
implementation has two problems:
* Most links from the same web page are linked back to the same host. When the crawler tries to download web pages in parallel, servers will be flooded with requests. This is considered as "impolite".
* Standard BFS does not take the priority of a URL into consideration, not every page has the same level of quality and importance.

### URL frontier
A URL frontier is a data structure that stores URLs to be downloaded. The URL frontier is an important component to ensure politeness, URL prioritization, and freshness.

#### Politeness
A web crawler should avoid sending too many requests to the same hosting server within a short period:
* maintain a mapping from website hostnames to download (worker) threads
* Each worker has a separate FIFO queue and only downloads URLs obtained from that queue
* add a delay between two download tasks

Using Kafka, maps each host to a topic, and multiple works subscribe to the same topic.

#### Priority
We prioritize URLs based on usefulness, which can be measured by PageRank, website traffic, update frequency, etc.
1. The input URL will be passed to prioritizer(which handles URL prioritization)
2. Queue f1 to fn: Each queue has an assigned priority.
3. Queue selector: Randomly choose a queue with a bias towards queues with higher priority.

#### Freshness
A web crawler must periodically recrawl downloaded pages to keep our data set fresh. Few strategies to optimize freshness:
* Recrawl based on web pages' update history
* Prioritize URLs and recrawl important pages first and more frequently

#### Storage for URL Frontier
the number of URLs in the frontier could be hundreds of millions: The majority of URLs are stored on disk, maintain buffers in memory for enqueue/dequeue operations.

### HTML Downloader
#### Robots.txt
Robots.txt, called Robots Exclusion Protocol, is a standard used by websites to communicate with crawlers. It specifies what pages crawlers are allowed to download.

#### Performance optimization
1. Distributed crawl: To achieve high performance, crawl jobs are distributed into multiple servers, each downloader is responsible for a subset of the URLs.
2. Cache DNS Resolver: Maintaining our DNS cache to avoid calling DNS frequently for speed optimization. 
3. Locality: Distribute crawl servers geographicall. When crawl servers are closer to website hosts, crawlers experience faster download time.
4. Short timeout: If a host does not respond within a predefined time, the crawler will stop the job and crawl some other pages.

### Robustness
* Consistent hashing: distribute loads among downloaders, a new downloader server can be added or removed using consistent hashing
* Save crawl states and data: To guard against failures, crawl states and data are written to a storage system.
* Exception handling: web crawler must handle exceptions
* Data validation

### Extensibility
new modules can be extended:
* PNG Downloader module is plugged-in to download PNG files.
* Web Monitor module is added to monitor the web and prevent copyright and trademark infringements

### Detect and avoid problematic content
* Redundant content: Hashes or checksums
help to detect duplication
* Spider traps: A spider trap is a web page that causes a crawler in an infinite loop. For instance, an infinite deep directory structure is like: `www.spidertrapexample.com/foo/bar/foo/bar/foo/bar/...`. Such spider traps can be avoided by setting a maximal length for URLs, but it's hard to develop automatic algorithms to avoid all types of spider traps. 
* Data noise: advertisements, code snippets, spam URLs should be excluded


## Step 4 - Wrap up
characteristics of a good crawler:
* scalability
* politeness
* extensibility
* robustness

talking points:
* Server-side rendering: some website use scripts like JavaScript and AJAX to generate links. If we download and parse web pages directly, we will not be able to retrieve dynamically generated links.
* Filter out unwanted pages: an anti-spam component to filter out low quality and spam pages
* Database replication and sharding: replication and sharding are used to improve the data layer availability, scalability, and reliability
* Horizontal scaling: keep servers stateless -> thousands of servers perform download tasks
* Analytics: collect and analyze data
