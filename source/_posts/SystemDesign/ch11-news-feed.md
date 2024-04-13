---
title: System Design - News Feed
category:
  - System Design
tag:
  - System Design
abbrlink: f46c
date: 2024-04-17 12:42:10
keywords:
description:
---

## Step 1 - Understand the problem and establish design scope
* Is this a mobile app? Or a web app? Or both?: Both
* What are the important features?: A user can publish a post and see her friends’ posts on the news feed page
* Is the news feed sorted by reverse chronological order or any particular order: the feed is sorted by reverse chronological order
* How many friends can a user have?: 5000
* What is the traffic volume?: 10 million DAU
* Can feed contain images, videos, or just text?: It can contain media files, including both images and videos.

## Step 2 - Propose high-level design and get buy-in
The design is divided into two flows:
* Feed publishing: when a user publishes a post, data is written into cache and database. A post is populated to her friends’ news feed.
* Newsfeed building: the news feed is built by aggregating friends’ posts in reverse chronological order

### Newsfeed APIs
* Feed publishing API: client sends a HTTP POST request to the server to publish a post. For example: `POST /v1/me/feed`, params:
    * content: content is the text of the post
    * auth_token: it is used to authenticate API request
* Newsfeed retrieval API: client sends a HTTP GET request to the server to retrieve news feed. For example: `GET /v1/me/feed`, params:
    * auth_token: it is used to authenticate API requests

### Feed publishing
high-level design of the feed publishing flow:
* User: user can view news feeds on a browser or mobile app
* Load balancer: distribute traffic to web servers
* Web servers: redirect traffic to different internal services
* Post service: persist post in the database and cache
* Fanout service: push new content to friends' news feed. Newsfeed data is stored in the cache for fast retrieval
* Notification service: inform friends that new content is available and send out push notifications

### Newsfeed building
high-level design of the newsfeed building flow:
* User: user sends a request to retrieve her news feed
* Load balancer: distribute traffic to web servers
* Web servers: redirect requests to newsfeed service
* Newsfeed service: fetch news feed from the cache
* Newsfeed cache: store news feed IDs needed to render the news feed


## Step 3 - Design deep dive
### Feed publishing deep dive
we will focus on two components:
* web servers: only users signed in with valid auth_token are allowed to make posts. The system limits the number of posts a user can make within a certain period, prevent spam and abusive content
* fanout service: Fanout is the process of delivering a post to all friends. Two types of fanout models.

#### Fanout on write
news feed is pre-computed during write time. A new post is delivered to friends’ cache immediately after it is published.
* Pros: 
    * The news feed can be pushed to friends immediately
    * Fetching news feed is fast because the news feed is pre-computed
* Cons: 
    * If a user has many friends, fetching the friend list and generating news feeds for all of them are slow
    * For inactive users or those rarely log in, pre-computing news feeds waste computing resources

### Fanout on read
The news feed is generated during read time. Recent posts are pulled when a user loads her home page.
* Pros:
    * For inactive users or those who rarely log in, fanout on read works better
    * Data is not pushed to friends so there is no hotkey problem
* Cons:
    * Fetching the news feed becomes slow

Solution: hybrid approach to get benefits of both approaches:
* For the majority of users: use a push model 
* For users who have many friends/followers: let friends/followers pull news content to avoid system overload

### The fanout service workflow
1. Fetch friend IDs from the graph database: 
2. Get friends info from the user cache: filter out friends based on user settings
    * if user mutes someone, user's posts will not show up on their news feed
    * user could selectively share information with specific friends
3. Send friends list and new post ID to the message queue
4. Fanout workers fetch data from the message queue and store news feed data in the news feed cache
5. Store `<post_id, user_id>` in news feed cache

### Newsfeed retrieval deep dive
media content (images, videos, etc.) are stored in CDN for fast retrieval. 
1. A user sends a request to retrieve her news feed
2. The load balancer redistributes requests to web servers
3. Web servers call the news feed service to fetch news feeds
4. News feed service gets a list post IDs from the news feed cache
5. A user’s news feed is more than just a list of feed IDs
6. The fully hydrated news feed is returned in JSON format back to the client for rendering

### Cache architecture
We divide the cache tier into 5 layers:
* News Feed: store IDs of news feeds
* Content: store every post data
* Social Graph: store user relationship data
* Action: store info about whether a user liked a post, replied a post, or took other actions on a post
* Counters: store counters for like, reply, follower, following, etc


## Step 4 - Wrap up
high-level talking points:
* Vertical scaling vs Horizontal scaling
* SQL vs NoSQL
* Master-slave replication
* Read replicas
* Consistency models
* Database sharding
