---
title: System Design - Chat System
category:
  - System Design
tag:
  - System Design
abbrlink: 601d
date: 2024-04-18 12:42:10
keywords:
description:
---

## 1. Understand the problem and establish design scope
* What kind of chat app shall we design? 1 on 1 or group based: It should support both 1 on 1 and group chat
* Is this a mobile app or a web app: Both
* What is the scale of this app: It should support 50 million daily active users (DAU)
* For group chat, what is the group member limit: A maximum of 100 people
* What features are important for the chat app: 1 on 1 chat, group chat, online indicator. The system only supports text messages.
* Is there a message size limit: Yes, text length should be less than 100,000 characters long
* Is end-to-end encryption required: Not required for now but we will discuss that if time allows
* How long shall we store the chat history: Forever

Features of a chat app:
* A one-on-one chat with low delivery latency
* Small group chat (max of 100 people)
* Online presence
* Multiple device support
* Push notifications


## 2. Propose high-level design and get buy-in
In a chat system, clients can be either mobile applications or web applications. Clients do not communicate directly with each other. Instead, client connects to a chat service, which supports all the features mentioned above. The chat service must support the following functions:
* Receive messages from other client
* Find the right recipients for each message and relay the message to the recipients
* If a recipient is not online, hold the messages for that recipient on the server until she is online

![Chat Service](/images/System-Design/Interview/12-chat-service.jpg)

When a client intends to start a chat, it connects the chats service using one or more network protocols:
* on the sender side: HTTP is a fine option, and many chat applications such as Facebook used HTTP to send messages
* on the receiver side: Since HTTP is client-initiated, it is not trivial to send messages from the server. Other techniques are used to simulate a server-initiated connection:  polling, long polling, and WebSocket.

### 2.1 Polling
![Polling](/images/System-Design/Interview/12-polling.jpg)

Client periodically asks the server if there are messages available. The cost of polling depends on polling frequency. 

### 2.2 Long polling
![Long Polling](/images/System-Design/Interview/12-long-polling.jpg)

In long polling, a client holds the connection open until
* there are actually new messages available
* timeout threshold has been reached

Once the client receives new messages or reaches timeout threshold, it immediately sends another request to the server. Long polling has a few drawbacks:
* Sender and receiver may not connect to the same chat server. HTTP servers are usually stateless, the server that receives the message might not have a long-polling connection with the client who receives the message.
* A server has no good way to tell if a client is disconnected
* If a user does not chat much, long polling still makes periodic connections after timeouts

### 2.3 WebSocket
![WebSocket](/images/System-Design/Interview/12-websocket.jpg)

WebSocket connection is initiated by the client. It is bi-directional and persistent. Through this persistent connection, a server could send updates to a client. By using WebSocket for both sending and receiving.

### 2.4 Long Polling vs WebSocket
* Long Polling:
    * Advantages: Long polling is implemented on `XMLHttpRequest`, so nearly all devices support long polling
    * Disadvantages: more resource intensive on the server than WebSocket; could have message ordering issue if a client has two browser tabs open consuming the same server resource
* WebSockets:
    * Advantages: low latency since only one connection and Full-duplex asynchronous messaging; HTTP headers are not sent on each server request, reduce the size of data payloads.
    * Disadvantages: don’t automatically recover when connections are terminated; Browsers older than 2011 aren’t able to support

### 2.4 High-Level Design
Most features (sign up, login, user profile, etc) of a chat application could use the traditional request/response method over HTTP. The chat system is broken down into three categories: stateless services, stateful services, and third-party integration.
![High Level Design](/images/System-Design/Interview/12-high-level-design.jpg)

#### 2.4.1 Stateless Services
Stateless services are traditional public-facing request/response services, used to manage the login, signup, user profile, etc. Stateless services sit behind a load balancer. These services can be monolithic or individual microservices. 

#### 2.4.2 Stateful Service
The only stateful service is the chat service. The service is stateful because each client maintains a persistent network connection to a chat server. A client doesn't switch to another chat server as long as the server is still available. 

#### 2.4.3 Third-party integration
Push notification is the most important third-party integration, refer to chapter 10

#### 2.4.4 Scalability
Assuming each user connection needs 10K of memory, 1M concurrent users, it only needs about 10GB of memory to hold all the connections in a single server; But it may raise a big red flag in for the interview: No interviewer would accept a design in such scale.

![Adjusted High Level Design](/images/System-Design/Interview/12-adjusted-high-level-design.jpg)

Client maintains a persistent WebSocket connection to a chat server for real-time messaging:
* Chat servers facilitate message sending/receiving
* Presence servers manage online/offline status
* API servers handle everything including user login, signup, change profile, etc
* Notification servers send push notifications
* The key-value store is used to store chat history

#### 2.4.5 Storage
To make an decision on the type of database, we will examine the data types and read/write patterns. Two types of data exist in a typical chat system:
* generic data: user profile, setting, user friends list. These data are stored in robust and reliable relational databases. Replication and sharding are common techniques to satisfy availability and scalability.
* unique to chat system: chat history. It is important to understand the read/write pattern:
    * The amount of data is enormous
    * Only recent chats are accessed frequently. Users don't look up for old chats.
    * users might use features that require random access of data, such as search, view your mentions, jump to specific messages, etc
    * The read to write ratio is about 1:1 for 1 on 1 chat

We choose key-value stores for the following reasons:
* Allow easy horizontal scaling
* Provide very low latency to access data
* When the indexes grow large, random access is expensive in relational database
* Adopted by other proven reliable chat application. For example, Facebook messenger uses HBase, and Discord uses Cassandra

### 2.5 Data models
#### 2.5.1 Message table for 1 on 1 chat
The primary key is `message_id`, which helps to decide message sequence. We cannot rely on `created_at` to decide the message sequence because two messages can be created at the same time.
![1-on-1 Chat Data Model](/images/System-Design/Interview/12-data-model-1-on-1-chat.jpg)

#### 2.5.1 Message table for group chat
The composite primary key is `(channel_id, message_id)`, `channel_id` is the partition key because all queries in a group chat operate in a channel.
![Group Chat Data Model](/images/System-Design/Interview/12-data-model-group-chat.jpg)

#### 2.5.1 Message ID
`message_id` must satisfy the following two requirements:
* IDs must be unique
* IDs should be sortable by time: new rows have higher IDs than old ones

Solution: 
1. `auto_increment` keyword in MySql.
2. use a global 64-bit sequence number generator like `Snowflake`.
3. use local sequence number generator. The ID are only unique within a group


## 3. Design deep dive
### 3.1 Service discovery
The primary role of service discovery is to recommend the best chat server for a client based on the criteria like geographical location, server capacity, etc. Apache Zookeeper is a open-source solution for service discovery. It registers all the available chat servers and picks the best chat server for a client based on predefined criteria.

![Service Discovery](/images/System-Design/Interview/12-service-discovery.jpg)

1. User A tries to log in to the app
2. The load balancer sends the login request to API servers
3. After the backend authenticates the user, service discovery finds the best chat server for user. In this example, server 2 is chosen and the server info is returned back to User A.
4. User A connects to chat server 2 through WebSocket

### 3.2 Message flows
#### 3.2.1 1 on 1 chat flow
![1 on 1 Chat Flow](/images/System-Design/Interview/12-1-on-1-chat-flow.jpg)

1. User A sends a chat message to Chat server 1
2. Chat server 1 obtains a message ID from the ID generator
3. Chat server 1 sends the message to the message sync queue
4. The message is stored in a key-value store
    * If User B is online, the message is forwarded to Chat server 2 where User B is connected
    * If User B is offline, a push notification is sent from push notification (PN) servers
5. Chat server 2 forwards the message to User B

#### 3.2.2 Message synchronization across multiple devices
Assuming user A has two devices: a phone and a laptop
![Message Synchronization](/images/System-Design/Interview/12-message-sync.jpg)

* When User A logs in with phone, it establishes a WebSocket connection with Chat server 1
* When User A logs in with laptop, also establishes a WebSocket connection with Chat server 1

Each device maintains a variable called `cur_max_message_id`, which keeps track of the latest message ID on the device. New messages should satisfy the following two conditions:
* The recipient ID is equal to the currently logged-in user ID
* Message ID in the key-value store is larger than `cur_max_message_id`

#### 3.2.3 Small group chat flow
Assume there are 3 members in the group (User A, User B and user C)
![Group Chat Flow](/images/System-Design/Interview/12-group-chat-flow.jpg)

1. the message from User A is copied to each group member's message sync queue: one for User B and the second for User C. This design choice is good for small group chat because:
    * It simplifies message sync flow as each client only needs to check its own inbox to get new messages
    * when the group number is small, store a copy in each recipient's inbox is not too expensive
2. Each recipient has an inbox (message sync queue) which contains messages from different senders

### 3.3 Online presence
In the high-level design, presence servers are responsible for managing online status and communicating with clients through WebSocket. There are a few flows that will trigger online status change.

#### 3.3.1 User login
After a WebSocket connection is built between the client and the real-time service, user A's online status and `last_active_at` timestamp are saved in the KV store. Presence indicator shows the user is online after she logs in.

#### 3.3.2 User logout
The online status is changed to offline in the KV store. The presence indicator shows a user is offline.

#### 3.3.3 User disconnection
When a user disconnects from the internet, the persistent connection between the client and server is lost. 
* When user disconnects, mark the user as offline and change the status to online when the connection re-establishes: result in poor user experience
* heartbeat mechanism: client sends a heartbeat event to presence servers. If presence servers receive a heartbeat event within a certain time, the user is considered as online; Otherwise, it is offline.

![User Disconnection](/images/System-Design/Interview/12-user-disconnection.jpg)

#### 3.3.4 Online status fanout
Presence servers use a publish-subscribe model, in which each friend pair maintains a channel. When User A's online status changes, it publishes the event to three channels, channel A-B, A-C, A-D. Those three channels are subscribed by User B, C, D.
![Online Status Fanout](/images/System-Design/Interview/12-online-status-fanout.jpg)

The above design is effective for a small user group. Assume a group has 100,000 members, each status change will generate 100,000 events. To solve the performance bottleneck, a possible solution is to fetch online status only when a user enters a group or manually refreshes the friend list.


## 4. Wrap up
* chat system: support 1-to-1 chat and small group chat
* websocket is used for real-time communication
* components:
    * chat servers for real-time messaging
    * presence servers for managing online presence
    * push notification servers for sending push notifications
    * key-value stores for chat history persistence
    * API servers for other functionalities

talking points:
* Support media files such as photos and videos
* End-to-end encryption
* Caching messages on the client-side to reduce the data transfer between the client and server
* Improve load time: build a geographically distributed network to cache users' data
* Error handling:
    * If a chat server goes offline, service discovery (Zookeeper) will provide a new chat server for clients to establish new connections
    * Message resent mechanism. Retry and queueing are common techniques for resending messages
