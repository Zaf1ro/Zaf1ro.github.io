---
title: System Design - Interview
category:
  - System Design
tag:
  - System Design
abbrlink: 830d
date: 2024-04-09 12:42:10
keywords:
description:
---

## 1. Understand the problem and establish design scope
Ask questions to understand the exact requirements. Here is a list of questions to help you get started:
* What specific features are we going to build?
* How many users does the product have?
* How fast does the company anticipate to scale up? What are the anticipated scales in 3 months, 6 months, and a year?
* What is the company’s technology stack? What existing services you might leverage to simplify the design?

Example: design a news feed system
Questions:
* Is this a mobile app? Or a web app? Or both? -> Both
* What are the most important features for the product? -> make a post and see friends’ news feed
* Is the news feed sorted in reverse chronological order or a particular order? -> e feed is sorted by reverse chronological order.
* How many friends can a user have? -> 5000
* What is the traffic volume? ->  10 million daily active users (DAU)
* Can feed contain images, videos, or just text? -> yes, including both images and videos.


## 2. Propose high-level design and get buy-in
develop a high-level design and reach an agreement with the interviewer on the design.
* Come up with an initial blueprint for the design
* Draw box diagrams with key components on the whiteboard or paper
* Do back-of-the-envelope calculations to evaluate if your blueprint fits the scale
constraints.

Example: Design a news feed system. The design is divided into two flows: feed publishing and news feed building.
* Feed publishing: when a user publishes a post, corresponding data is written into cache/database, and the post will be populated into friends’ news feed.
* Newsfeed building: the news feed is built by aggregating friends’ posts in a reverse
chronological order


## 3. Design deep dive
you and your interviewer should have already achieved the following objectives:
* Agreed on the overall goals and feature scope
* Sketched out a high-level blueprint for the overall design
* Obtained feedback from your interviewer on the high-level design
* Had some initial ideas about areas to focus on in deep dive based on her feedback

Example: investigate two of the most important use cases:
* Feed publishing
* News feed retrieval


## 4. Wrap Up
the interviewer might ask you a few follow-up questions or give you the freedom to discuss other additional points. Here are a few directions to follow:
* The interviewer might want you to identify the system bottlenecks and discuss potential improvements.
* It could be useful to give the interviewer a recap of your design.
* Error cases (server failure, network loss, etc.) are interesting to talk about
* Operation issues are worth mentioning. How do you monitor metrics and error logs? How to roll out the system?
* How to handle the next scale curve is also an interesting topic.
* Propose other refinements you need if you had more time.


