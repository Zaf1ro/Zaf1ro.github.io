---
title: job-experience
date: 2024-03-18 16:02:49
tags:
category:
keywords:
description:
---

## 1. ICC Project
### 1.1 Frontend migration
* Situation:
    IBM has deprecated the Northstar framework, prompting the need for a transition to the Carbon Design System, which aligns with our current and future design initiatives.
* Task:
    1. JSF is a user interface framework (API) that uses a component-centric approach to develop Java web user interfaces. But the online discussion about JSF 2.0 is relatively limited, hard to address specific issues with fewer resources. JSF allows very little fine-grained control over the generated HTML/CSS/JS.
    2. Many old web components are all manipulated using JavaScript, and it redeces maintainability and readability, so the code cannot be compatible when migrating to the Carbon Design System
* Action:
    1. create custom JSF components that encapsulate the functionality of Carbon Design System web components
    2. binding JSF managed bean properties to web component attributes
    3. Remove the DOM manipulation related to Northstar
* Result:
    Successfully migrating from Northstar to the Carbon Design System without altering functionality.


2. Backend Debug
* Situation:
    The testing team and clients encountered unexpected results while using the web app, requiring the development team to spend a significant amount of time  the issue and resolve.
* Tasks:
    1. As the project was developed and maintained a long time ago, many features have been disabled during iteration. It is now necessary to readded these features back into the system.
    2. The project was deployed to GitHub shortly before my joining, so it's hard to provide a complete history of what changed, and why it changed.
    3. The project lacks extensive documentation, and the codebase is lacking in comments. Additionally, many contributors to the codebase have already left the company due to resignation or retirement.
* Action:
    1. Create a Jira ticket upon encountering an issue reported by the testing team or customer.
    2. Connect Github with Jira so we can track the branch, commit or pull request in the context of Jira issue
    3. Begin documenting each components and regularly review and update documentation to reflect changes in the codebase
* Result:
    When issues arise, enable developers to quickly identify the problem and allow newcomers to become familiar with the project promptly.


Kafka:
* Situation: 用户大量创建document并上传文件, producer会将文件传递给Kafka集群, 由于consumer中的业务逻辑比较复杂, 需要先处理文件, 发送通知, 并保存文件, 导致consumer无法追赶上producer的生产速度.
* Task: 由于consumer无法及时消耗掉page cache中的数据, 导致page cache中的数据越来越多, Linux不得不将数据flush到dish上. 因此consumer无法通过zero copy的方式从pagecache上读取数据, 只能从disk上读取到page cache, 再传输给consumer. Page cache受到producer和consumer的双重压力, 导致运行越来越慢.
* Action:
    * Customer Group中的consumer数量与topic中的partition数量一致, 实现并行处理最大化
    * 使用更好的硬件, 扩大page cache
    * 每个consumer维护一个thread pool, 让consumer可以并行处理多个文件. 但由于consumer不是线程安全的, 因此一旦某个线程出现故障, 可能导致重复消费
    * 增加partition数量, 从而增加consumer数量, 但会影响其他业务, 因此放弃

Kafka:
* Sitation: 应用需要定期向用户发送通知, 应用必须保证所有用户都收到通知, 不能丢失通知
* Task: 开发过程中, Kafka默认开启enable.auto.commit. worker(consumer)从Kafka集群中获取数据后, 会一一处理消息, 并向相应的用户发送通知. 但有时由于邮件地址无效或邮件模板生成错误, 会导致consumer关闭并自动提交offset, 重启后的worker不会处理该消息.
* Action:
    * For consumer: 关闭enable.auto.commit参数, 并手动提交offset
    * For producer: 设置acks=10, retries=10, 保证用户
* Result: 保证了通知一定能发送到用户的邮件中

