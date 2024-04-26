## Walk me through your resume and background
Hello, I'm Jason, delighted to connect with you today to discuss the software engineering position.
In my previous role at IBM, I worked as a full stack engineer for a web application which had been running for almost 20 years.
* I had the opportunity to specialize in the development of RESTful APIs using Java, Spring Boot, and Node.js for the backend service.
* I've also worked on the migration of applications to the IBM Cloud, implemented scalable microservice architectures.
* experience with design and implement a real-time data processing system using Apache Kafka to handle large volumes of data from clients
* Additionally, I've designed and optimized database system, including SQL and NoSQL database like IBM Db2 and MongoDB.
* I'm excited about this opportunity to contribute to next project. Thank you.


## What is something you are most proud of this far in your career?
One of the achievements I'm most proud of in my career thus far is leading the migration of our application from a single server environment to the IBM Public Cloud.
* Change version control from RTC to Github since RTC is not cloud native
* Moved storage layer on the IBM Cloud platform, such as IBM Db2 for relational database management, MongoDB for NoSQL database, and Kafka for real-time data streaming
* Change from stateful to stateless service: Migrate from JavaServer Faces (JSF) application to a RESTful API architecture using Spring Boot, Spring MVC
* Next, containerized each of web services using Docker
* configured GitHub webhooks and Set up CI/CD pipeline workflow whenever changes were pushed to the repository


## Explain a time you implemented a transformative process before
* Situation: In my previous project, we implement Kafka cluster for decoupling the data streams. When users created a large number of documents which included multiple files. The API server will deliver the file to Kafka cluster, and the backend services will validate these file, send notification to target customer, and store the file in IBM Cloud.
* Task: The consumer couldn't keep up with consuming the data stored in the Kafka. This caused an accumulation of data in the page cache, then Linux started to flush data to the disk. So the consumer have to read data from disk instead of page cache. Also, page cache needs to free up space for the data sent by the producer. Therefore, page cache needs to write data to disk while also read data from disk, made the whole system slower.
* Action: 
    * We aligned the number of consumers in the Consumer Group with the number of partition in the topic
    * Upgraded our hardware: bigger page cache, the more powerful consumer
    * Implemented a thread pool for each consumer, so each consumer can process several files at the same time
    * increased the number of partition, but had an impact on the other business process


## What is a strength of yours?
One strength I possess is my ability to effectively solve complex problems. In my previous role as a full stack software engineer, we encountered several critical issues where our application was giving unexpected results to our customer and stakeholders.
The issue usually came from the corner case of the business logic.
* Firstly, I lead the test team to reproduce the issue on the test environment
* Secondly, I worked with product manager to gain a deep understanding of the business rules and requirements, diagnose the root cause of the problem, and also conducted a comprehensive analysis of our codebase.
* In the end, we fixed the bug, test in the preproduction environment 

My ability to dive deep into the problem, collaborate with team members, and devise effective solutions played a crucial role in resolving the issue. As a result, we received positive feedback from stakeholders.


## Tell me a time when you made a suggestion for clients
## Do you have a attention to detail?
* Situation: In a project where I was responsible for maintaining a large-scale web application, we encountered a significant performance issue with the loading time of the homepage, which happened to be the most visited page on our website.
* Task: I reported to my manager and tasked to address this performance issue which ensures a good service experience.
* Action: I delved into analyzing the underlying factors contributing to the slow loading time. After thorough investigation and performance testing, I identified that the bottleneck was related to inefficient SQL queries fetching data for the homepage. I optimized the index in table to improve the efficiency of data retrieval operations.
* Result: By addressing performance issues, we were able to deliver great service to our large user base.

In a previous project, I was tasked with optimizing the performance of a critical database query that was slowing down the homepage response time, which is the most visited page on our website.
I realized the critical importance of addressing it to improve user experience and business metrics.
The query involved complex joins and aggregations on different tables. To address this challenge, I began by analyzing the query execution plan and found certain database tables lacked appropriate indexes, when multiple users were accessing the same data simultaneously, it will lead to access block and delay.
So we added and refined indexes to improve data retrieval efficiency. Additionally, we implemented caching mechanisms to further enhance the responsiveness of the homepage. In the end, we successfully reduced the query execution time by 50% and eliminated the occurrence of timeouts and concurrency issues during peak usage.


## When you're working with a large number of customers, it's tricky to deliver excellent service to them all. So how do you go about prioritzing your customers' needs?
I usually engage in discussions with my team and leadership and gather all the project goals and assess their impact on our customers. 
* if there are customer-reported bugs that block them to proceed with their tasks, I prioritize addressing those first. These fixes typically require immediate attention and can be resolved within 3-4 days.
* I consider new features that could enhance the overall user experience. While these may not be as urgent as bug fixes, they contribute to long-term customer satisfaction. I aim to allocate adequate resources and time, typically around a month, to implement these features.
* I address tasks such as optimizing database connections, which improve code readability and maintainability. While important for long-term system health, these tasks are typically less urgent and can be scheduled after addressing immediate customer needs.


## Tell me about a time you failed/were wrong/made a mistake/had an error in judgement/made a bad decision
* Situation: In my previous project, our application required regular notification delivery to users, and have to ensure that all users received their notifications without any loss. Different service will deliver the notification to Kafka cluster, and notification service will poll from Kafka cluster and send email to customer.
* Task: During the development process, we didn't make any change on `enable.auto.commit` setting on consumer in notification service. When the consumer receive an invalid email address or throw exception when generating the email template, it will close the consumer and automatically commit offsets. As a result, when worker restarted and poll message, it will skip the unfinished message.
* Action: For the consumer side: I disabled the `enable.auto.commit` parameter and implemented manual offset commits. For the producer side: I configured `acks=10` and `retries=10` to guarantee the Kafka cluster received the message.
* Result: By implementing these actions, we can ensure that notifications were reliably delivered to users' emails.

## Tell me a time you have been stressed / overwhelmed.
* Situation: For implementing the microservice architecture, we separated authentication service from application code, also rearchitecture the data structure within session.
* Task: My responsibility involved implementing changes to the data structure, including changing the field name of identifer and user access level. During testing, the test account works fine with login functionality. But when deployed on the production environment, some customer were unable to login with their account.
* Action: I conducted a investigation into the issue immediately, and found there's two different types of session data structures present in the database. The older structure was incompatible with the authentication service, resulting in denied user access. To resolve this, we cleared the cache to ensure consistency across the cache server.
* Result: all customer was able to login as the end.


## Tell me about a time when you had to work on a project with unclear responsibility
* Situation: 


## In what you have learned so far about this role, do you have additional question you'd like to ask.
根据公司不同, 做出不同回答


## Tell me about a time you disagreed with a colleague or boss. What is the process you used to work it out?
* Situation: When I worked in IBM, there was a requirement to implement the new UI design system on the legacy web application.
* Task: However, there was a conflict regarding how to integrate this new design system. Some developers said we should directly replacing JSP markup with React components. And I believed that such a huge change could introduce numerous unexpected errors and significantly extend the development timeline, so I disagreed with the idea.
* Action: To validate my concerns, we decided to experiment by attempting to convert a few pages to React components. The process proved to be complex, requiring modifications to both frontend and backend code. 
* Result: we decided to replace JSP markup with React components on part of webpages with more complicated business logic. The other pages only adopt the new design style with new design system. This experience taught me the importance of balancing innovation with practical considerations and the value of compromise in reaching optimal solutions.


## When do you think it's ok to push back or say no to an unreasonable customer request?
* Situation: In a recent project, a customer approached us with a request to remove archived workspaces from their system.
* Task: My task was to assess the feasibility of the request and determine the best action to address the customer's concerns.
* Action: After investigating the archived workspaces, I discovered that some archived workspaces still had shared data with active workspaces, which means potential data dependencies. To minimizing the risk of breaking data consistency, I communicate with customer to understand their underlying needs, and learned that every customer visit the page of workspace list, they need to scroll down the page to skip the archived workspace and click into the workspace they want.
* Result: After listening to the customer's feedback, I Implemented the filter feature to allowing customers to focus on relevant workspaces. This enhancement not only increased user satisfaction, but also keep the data consistency.

