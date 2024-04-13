---
title: System Design - Notification System
category:
  - System Design
tag:
  - System Design
abbrlink: 9f54
date: 2024-04-16 12:42:10
keywords:
description:
---

## Introduction
A notification alerts a user with important information like breaking news, product updates, events, offerings, etc. Three types of notification formats:
* mobile push notification
* SMS message
* Email


## Step 1 - Understand the problem and establish design scope
* What types of notifications does the system support?: Push notification, SMS message, and email
* Is it a real-time system?: a soft real-time system, if the system is under a high workload, a slight delay is acceptable
* What are the supported devices?: iOS devices, android devices, and laptop/desktop
* What triggers notifications?: Notifications can be triggered by client applications. They can also be scheduled on the server-side.
* Will users be able to opt-out?: Yes, users who choose to opt-out will no longer receive notifications
*  How many notifications are sent out each day?: 10 million mobile push notifications, 1 million SMS messages, and 5 million emails.


## Step 2 - Propose high-level design and get buy-in
### Different types of notifications
* iOS push notification: three components to send an iOS push notification.
    * Provider: build and send notification requests to Apple Push Notification Service (APNS)
    * APNS: provided by Apple to propagate push notifications to iOS devices
    * iOS Device: It is the end client, which receives push notifications.
* Android push notification: Firebase Cloud Messaging(FCM) is commonly used to send push notifications to android devices
* SMS message: third party SMS services like Twilio, Nexmo, and many others are commonly used. Most of them are commercial services.
* Email: many of company opt for commercial email services which offer a better delivery rate and data analytics

### Contact info gathering flow
when a user installs our app or signs up for the first time, API servers collect user contact info and store it in the database:
* Email addresses and phone numbers are stored in the `user` table
* device tokens are stored in the `device` table

### Notification sending/receiving flow
#### High-level design
* Service 1 to N: A service can be a micro-service, a cron job, or a distributed system that triggers notification sending events.
* Notification system: centerpiece of sending/receiving notifications. It provides APIs for services 1 to N, and builds notification payloads for third party services.
* Third-party services: e responsible for delivering notifications to users
    * extensibility : system should easily plug or unplug of a third-party service
    * navailablility : system should be availble for all time and regions
* iOS, Android, SMS, Email: Three problems:
    * Single point of failure (SPOF)
    * Hard to scale: It is challenging to scale databases, caches, and different notification processing components independently
    * Performance bottleneck: Processing and sending notifications can be resource intensive.
* High-level design: 
    * Move the database and cache out of the notification server
    * Add more notification servers and set up automatic horizontal scaling
    * Introduce message queues to decouple the system components

how every component works together to send a notification:
1. A service calls APIs provided by notification servers to send notifications.
2. Notification servers fetch metadata such as user info, device token, and notification setting from the cache or database
3. A notification event is sent to the corresponding queue for processing.
4. Workers pull notification events from message queues.
5. Workers send notifications to third party services.
6. Third-party services send notifications to user devices.


## Step 3 - Design deep dive
### Reliability
#### How to prevent data loss?
The notification system cannot lose data. Notifications can usually be delayed or re-ordered, but never lost. Thus, the notification system persists notification data in a database and implements a retry mechanism. 

#### Will recipients receive a notification exactly once?
No. Although notification is delivered exactly once most of the time, the distributed system could result in duplicate notifications. Here is a simple dedupe logic: When a notification arrives, we check the event ID to see if it's seen before. If it is seen before, it is discarded; Otherwise, we will send out the notification. 

### Additional components and considerations
#### Notification template
Notification templates are introduced to avoid building every notification from scratch. The benefits of using notification templates include maintaining a consistent format, reducing the margin error, and saving time.

#### Notification setting
Before any notification is sent to a user, we first check if a user is opted-in to receive this type of notification.

#### Rate limiting
limit the number of notifications a user can receive. receivers could turn off notifications completely if we send too often.

#### Retry mechanism
When a third-party service fails to send a notification, the notification will be added to the message queue for retrying. If the problem persists, an alert will be sent out to developers.

#### Security in push notifications
Only authenticated or verified clients are allowed to send push notifications using our APIs.

#### Monitor queued notifications
A key metric to monitor is the total number of queued notifications. If the number is large, the notification events are not processed fast enough by workers.

#### Events tracking
Open rate, click rate, and engagement are important in understanding customer behaviors. 

### Updated design
many new components are added in comparison with the previous design:
* The notification servers are equipped with two new features: authentication and rate-limiting.
* add a retry mechanism to handle notification failures.
* notification templates provide a consistent and efficient notification creation process
* monitoring and tracking systems are added for system health checks and future improvements


## Step 4 - Wrap up
* Reliability: a robust retry mechanism to minimize the failure rate
* Security: AppKey/appSecret pair is used to ensure only verified clients can send notifications
* Tracking and monitoring: These are implemented in any stage of a notification flow to capture important stats
* Respect user settings: Users may opt-out of receiving notifications
* Rate limiting
