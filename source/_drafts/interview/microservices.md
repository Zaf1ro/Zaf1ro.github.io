---
title: microservices
date: 2024-03-18 12:34:25
tags:
category:
keywords:
description:
---

the Microservices Architecture pattern has significant benefits – especially when it comes to enabling the agile development and delivery of complex enterprise applications.

designing, building, and deploying microservices

the benefits and drawbacks of the Microservices Architecture pattern


## Building Monolithic Applications
After some preliminary meetings and requirements gathering, you would create a new project either manually or by using a generator that comes with Rails, Spring Boot, Play, or Maven
At the core of the application is the business logic, which is implemented by modules that define services, domain objects, and events. Surrounding the core are adapters that interface with the external world. Examples of adapters include database access components, messaging components that produce and consume messages, and web components that either expose APIs or implement a UI.
the application is packaged and deployed as a monolith. The actual format depends on the application’s language and framework. For example, many Java applications are packaged as WAR files and deployed on application servers such as Tomcat or Jetty.
You can implement end‑to‑end testing by simply launching the application and testing the UI with Selenium. Monolithic applications are also simple to deploy. You just have to copy the packaged application to a server. You can also scale the application by running multiple copies behind a load balancer.

### problem
One major problem is that the application is overwhelmingly complex. It’s simply too large for any single developer to fully understand. As a result, fixing bugs and implementing new features correctly becomes difficult and time consuming.
Monolithic applications can also be difficult to scale when different modules have conflicting resource requirements.
Another problem with monolithic applications is reliability. Because all modules are running within the same process, a bug in any module, such as a memory leak, can potentially bring down the entire process.


## Microservices 
Instead of building a single monolithic application, the idea is to split your application into set of smaller, interconnected services.
A service typically implements a set of distinct features or functionality, such as order management, customer management. Each microservice is a mini‑application that has its own architecture consisting of business logic along with various adapters.
Some microservices would expose an API that’s consumed by other microservices or by the application’s clients. Other microservices might implement a web UI.
Each backend service exposes a REST API and most services consume APIs provided by other services. Services might also use asynchronous, message‑based communication.
Some REST APIs are also exposed to the mobile apps used by the drivers and passengers. The apps don’t, however, have direct access to the backend services. Instead, communication is mediated by an intermediary known as an API Gateway. The API Gateway is responsible for tasks such as load balancing, caching, access control, API metering, and monitoring, and can be implemented effectively using NGINX.

### Benefits
First, it tackles the problem of complexity. It decomposes what would otherwise be a monstrous monolithic application into a set of services. While the total amount of functionality is unchanged, the application has been broken up into manageable chunks or services. Each service has a well‑defined boundary in the form of an RPC‑ or message‑driven API.
Second, this architecture enables each service to be developed independently by a team that is focused on that service. The developers are free to choose whatever technologies make sense, provided that the service honors the API contract.
Third, the Microservices Architecture pattern enables each microservice to be deployed independently. Developers never need to coordinate the deployment of changes that are local to their service.
Finally, the Microservices Architecture pattern enables each service to be scaled independently. You can deploy just the number of instances of each service that satisfy its capacity and availability constraints.

### Drawback
The major drawback of microservices is the complexity that arises from the fact that a microservices application is a distributed system. Developers need to choose and implement an inter‑process communication mechanism based on either messaging or RPC.  Moreover, they must also write code to handle partial failure since the destination of a request might be slow or unavailable.
Another challenge with microservices is the partitioned database architecture. Business transactions that update multiple business entities are fairly common. These kinds of transactions are trivial to implement in a monolithic application because there is a single database.
In a microservices‑based application, however, you need to update multiple databases owned by different services. You end up having to use an eventual consistency based approach, which is more challenging for developers.
Another major challenge with the Microservices Architecture pattern is implementing changes that span multiple services. In a Microservices Architecture pattern you need to carefully plan and coordinate the rollout of changes to each of the services.