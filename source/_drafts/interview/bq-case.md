## Walk me through your resume and background
Hello, I'm Jason, delighted to connect with you today to discuss the software engineering position.
In my previous role at IBM, I worked as a full stack engineer for a web application which had been running for almost 20 years.
* I had the opportunity to specialize in the development of RESTful APIs using Java, Spring Boot, and Node.js for the backend service.
* I've also worked on the migration of applications to the IBM Cloud, implemented scalable microservice architectures.
* experience with design and implement a real-time data processing system using Apache Kafka to handle large volumes of data from clients
* Additionally, I've designed and optimized database system, including SQL and NoSQL database like IBM Db2 and MongoDB.
* I'm excited about this opportunity to contribute to next project. Thank you.


## What is something you are most proud of this far in your career?
1. Example
Situation: IBM鼓励各个部门将application迁移到云上, 我的领导要求每个人在短时间内将各自负责的项目迁移到IBM Cloud上
Task: 对于我来说, 在加入IBM之前我没有将项目迁移到cloud上的经验, 因此需要在短时间内快速学习相关知识, 如Docker, Kubernetes和Cloud Platform
Action: 开始项目前, 我先与technical leader进行了沟通, 了解到我们组并没有相关经验, 但我在IBM Github中找到了类似的项目, 并参考Docker的官方文档将application成功运行在docker container中, 之后我尝试将项目在IBM Cloud上运行一个demo, 在与scrum leader确认项目运行无误后, 我们将其部署到production environment
Result: 通过这次项目, 我有了将项目迁移到云上的经验, 并且学到了很多云相关的知识

* Situation: At IBM, there was a company-wide initiative to migrate applications to the cloud, and my team leader wanted us with migrating the projects to IBM Cloud within a short timeframe.
* Task: As someone who had no prior experience with migrating projects to the cloud, I need to quickly learning technologies such as Docker, Kubernetes, and IBM Cloud.
* Action:
    * Before starting the project, I started a discussions with the technical leader and knew that our team didn't have the similar experience in cloud migration.
    * However, I found some similar projects on IBM GitHub and decided to leverage them as learning resources.
    * I studied Docker documentation and successfully ran our application in a Docker container.
    * Then I attempted to deploy a demo on IBM Cloud. After confirming there's no firewall issue between server and database, and no HTTPS license issue, I proceeded to deploy it to the production environment.
* Result: Through this project, I gained valuable experience in migrating projects to the cloud. And this experience aslo allowed me to prepared for the future challenges in cloud infrastructure.

2. Example
* Situation: 当用户在网站中上传文件时, 我们使用Kafka来实现异步处理, 从而降低用户等待时间
* Task: 但有时会出现等待时间增长
* Action: 等待时间增加的原因有很多, 因此我逐步进行了以下调查:
    * 首先, 检查了用户的网络状态, 并检查IBM Cloud是否处于维护状态
    * 我们发现当大量用户同时上传文件时, 才会出现等待时间增加
    * 其次, 我们检查了consumer端的metrics, 发现consumer的处理速度不足以跟上producer的生成速度
    * 最后, 我们发现数据会大量积累到page cache中, 并频繁触发flush data, 因此我们在consumer端采用thread pool以提高其处理能力
* Result: 在进行了一系列优化后, 用户等待的时间明显降低. 我们也从问题中更好的了解Kafka原理, 并设置了monitoring机制来防止类似问题出现

* Situation: In our web application, I implemented Kafka for asynchronous processing of file uploads to reduce user wait times.
* Tasks: But sometimes there may be an increase in waiting time.
* Actions: To find the root cause of this issue, 
    * Firstly, I checked the user's network status and the status of Kafka in IBM Cloud
    * I found that the increased wait times occurred only when there's a high volume of file uploads.
    * Then I checked metrics on the consumer side and found that the consumer cannot keep up with the producer.
    * Finally, I identified an accumulation of data in the page cache, which leading the frequently data flush. To address this, I implemented a thread pool on the consumer side to improve its capacity.
* Result: After I implemented the optimization, I successfully reduced user wait times. I also established a monitoring mechanism to identify other performance issues


## Explain a time you implemented a transformative process before / improve user experience
Example 1: 
* Situation: 我们的网站允许用户上传文件. 当用户上传文件时, 用户需在页面长时间等待服务器处理. 
* Task: 为减少用户的等待时间, 我们总结等待时间的三个组成部分: 文件上传时间, 文件处理时间, 和文件保存时间. 我们对前两个等待时间进行了优化.
* Action:
    * 首先, 当用户上传一些小体积文件时, 我们会压缩文件后再上传
    * 其次, 我们会将文件的相关信息传递给Kafka(文件类型, 文件位置, 文件所处workspace, 文件owner), backend service可延迟处理文件
    * 当文件成功保存到磁盘后, 我们并直接告诉用户文件已成功处理
* Result: 用户等待的时间明显降低. 我通过这次优化也学习到了Kafka的配置和部署

* Situation: I have a website which allow user to upload file, and the problem is that users have to wait a long time to get response from server.
* Task: First, I have to identified why it's slow. The whole wait time can be separated into three components: file upload time, file processing time, and the time to save file. And for developer, I can optimized the first two waiting times.
* Action:
    * For image file, I made them smaller by compressing them before uploading. This reduced upload time.
    * I sent information about the files, like type of file, file location, and file owner, to Kafka. This meant our system could send response to client before processing these files, which saved time for users.
* Result: These changes made a big difference. The wait time almost decreased half. And I also learned about Kafka configuration and deployment through this optimization. 


## What is a strength of yours?
* Situation: 我的其中之一的优点是effectively solve complex problem. 我负责维护一个大型网站with complex business logic, 该项目运行了接近20年, 有超过百万行的代码. 有时用户或测试团队会遇到一些意料之外的结果. 
* Task: 我的任务是短时间内处理这些问题, 因为这些问题会导致网站出错并阻止用户的进一步操作
* Action: 我经常会处理类似问题, 我总结了以下步骤来排查问题:
    * 首先, I lead the test team to reproduce the issue on the test environment
    * 其次, 我们排除是否是前端引发的问题, 如果是, 则更新前端代码
    * 如果前端正确, 则排查后端代码是否按照业务逻辑实现, 或是否存在没有考虑到的corner case, 若存在, 则更新代码
    * 最后, 查看数据库中的数据是否正确, 仍存在重复数据或错误数据, 则联系数据团队进行纠错
    * 通常上述步骤可解决绝大多数问题, 若不行, 则联系techical leader重新评估问题, 若需要, 则回滚代码版本
* Result: My ability to dive deep into the problem, collaborate with team members, and devise effective solutions played a crucial role in resolving the issue. 

* Situation: One of my strengths is effectively solving complex problems. I am responsible for maintaining a large website with complex business logic, which has been running for nearly 20 years and consists of over a million lines of code. Sometimes, users or the testing team encounter unexpected results.
* Task: My task is to address these issues quickly, as they can cause the website to malfunction and prevent users from proceeding further.
* Action: I frequently deal with similar issues and have outlined the following steps to troubleshoot:
    * Firstly, I lead the test team to reproduce the issue on the test environment.
    * Next, I determine if the issue is caused by the frontend. If so, I update the frontend code.
    * If the frontend is correct, I investigate whether the backend code is implemented according to the business logic or if there are any overlooked corner cases. If issues are found, I update the code.
    * Finally, I check if the data in the database is correct. If there are still duplicate or incorrect data, I contact the data team for correction.
    * Typically, the above steps resolve the majority of issues. If not, I consult with the technical leader to reassess the problem and, if necessary, roll back the code version.
* Result: My ability to delve deep into the problem, collaborate with team members, and devise effective solutions played a crucial role in resolving the issue.


## Tell me a time when you made a suggestion for clients
## Do you have a attention to detail?
* Situation: 我经常会在测试环境中访问并测试自己负责的网站, 包括一些UI design和功能测试, 我发现其中一个网站的主页加载速度很慢
* Task: 我认为主页是最常访问的页面, 因此会极大影响用户体验, 在与product owner沟通后, 我们认为优化其加载速度是必要的
* Action:
    * 首先, 我发现不同用户访问该网页时, 加载时间并不相同, 说明并不是网络问题
    * 在查看network activity时, 我们发现其中一个http request耗时非常长, 发现是某个table在加载数据
    * 在查看后端代码后, 我们发现瓶颈在于一个SQL query statement, 其牵扯多个table的join操作, 因此我denormalize to reduce the need for complex joins by storing redundant data in related tables
* Result: 在我负责的网站中, 我极少收到与网站加载速度相关的customer complaint

* Situation: I often visit and test the website I'm responsible for in the testing environment, including some UI design and functionality testing. I noticed that it takes a lone time to load the homepage of website.
* Task: Since the homepage is the most visited page, so it will deeply affect the user experience. After discussion with the product owner, I agreed that optimizing its loading speed is very necessary.
* Action:
    * First, I noticed that the loading time varies when different users access the webpage, that mean it's not a network problem.
    * While checking network activity, I found that one of the HTTP requests was taking a really long time, and it turned out to be a table loading data.
    * After looking into the code in backend, I found the bottleneck to a SQL query statement that involved multiple table joins. So, I denormalized to reduce the need for complex joins by storing redundant data in related tables.
* Result: In the websites I'm in charge of, I hardly ever get any customer complaints related to website loading speed.


## When you're working with a large number of customers, it's tricky to deliver excellent service to them all. So how do you go about prioritzing your customers' needs?
I usually engage in discussions with my team and leadership and gather all the project goals and assess their impact on our customers. 
* if there are customer-reported bugs that block them to proceed with their tasks, I prioritize addressing those first. These fixes typically require immediate attention and can be resolved within 3-4 days.
* I consider new features that could enhance the overall user experience. While these may not be as urgent as bug fixes, they contribute to long-term customer satisfaction. I aim to allocate adequate resources and time, typically around a month, to implement these features.
* I address tasks such as optimizing database connections, which improve code readability and maintainability. While important for long-term system health, these tasks are typically less urgent and can be scheduled after addressing immediate customer needs.


## Tell me about a time you failed/were wrong/made a mistake/had an error in judgement/made a bad decision
* Situation: 我负责的项目中, 客户应受到系统发送的通知, 但有时个别用户会发现自己并没有受到通知.但是这是一个非常特殊的例子,因为我们在测试的时候并没有发现问题,以及大部分的客户确实收到了邮件. 
* Task: 我们需要快速找到问题所在, 并防止更多这类问题出现.
* Action:
    * 首先, 我让客户检查了他们的垃圾邮箱, 确保邮件没有被标记为spam
    * 之后, 我检查了Kafka, 发现kafka的确存在通知记录, 因此问题一定出现在notification service
    * 最后我们检查了notification service, 发现当消息发送失败时, 其仍会向Kafka提交消息. 
    * Dive into 这个问题之后发现, notification service端的consumer采用默认配置, 导致即使消息由于格式问题或网络问题而发送失败时, 也会自动提交消息. 我将其改为手动提交消息
Result: 我们又检查了所有项目的consumer配置, 并优化了测试流程, 确保其覆盖每一个失败案例.

* Situation: In the project I'm in charge of, customers are supposed to receive notifications email from the system. But sometimes, a few users find they haven't received any notifications. It's a pretty weird case since I didn't meet any issues during testing, and most customers did get the emails.
* Task: I need to quickly find the problem and stop more of these issue from happening.
* Action:
    * First off, I let the customers check their junk mail to make sure the emails isn't recognized as spam.
    * Then, I checked Kafka log and found that it had the notification message, so the issue had to be with the notification service.
    * After diving into it, I found out that the consumer on the notification service was using default settings, so even if messages failed to send due to formatting issues or network problems, it was still automatically submitting them. I switched it to manual submit.
* Result: I double-checked all the consumer configuration for all services and corrected our testing process to make sure it covers every possible situation.


## Tell me a time you have been stressed / overwhelmed.
* Situation: 为实现microservices, 我们将authentication service从项目中分离出来, 并重新设计了authentication logic和session management.
* Task: 我们在测试环境中尝试重现issue, 当我们将authentication service部署到production environment后, 很多用户告诉我们他们无法登录系统
* Action:
    * 该问题会影响用户的所有操作, 造成系统整体的瘫痪, 因此我们需要快速查找并解决问题,
    * 首先, 我查看了相关的代码逻辑, 并确保没有任何问题
    * 其次, 我们查看联系了数据团队, 查看了用户登录相关的session信息, 发现部分用户的session依然使用旧格式, 从而导致认证失败
    * 最后, 我们联系数据团队清理了session cache中的旧数据, 让用户可以重新登录
* Result: 为吸取这次教训, 我在github中创建了文档来记录这次问题, 并在代码中添加了comment来避免出现类似错误

* Situation: Since my project moves to microservices architecture, I separated the authentication service from the project and redesigned the authentication logic and session management.
* Task: After deploying to the test environment, I didn't encounter any issues. However, after deploying to the production environment, some users told us they couldn't log in. Since it's a system-wide breakdown, I need to quickly find and fix it.
* Action:
    * Firstly, I checked the deployed code and ensure there were no bug in the business logic.
    * Next, I contacted the database team and checked the session information related to user logins. I found that some users' sessions were still using the old format, leading to authentication failures.
    * Finally, I let data team to clean up the old data in the session cache to allow users to log in again.
* Result: To learn from this lesson, I writed down the issue description on Jira ticket and added comments in the codebase to prevent similar errors in the future.


## Tell me about a time when you had to work on a project with unclear responsibility
* Situation: 项目开发中, manager经常会向我提出一些从没接触过的问题, 我会向manager提出一些问题:
    * 确定项目impact使得我能确定重要和紧急情况
    * 确定prefered timeline
    * 由于是我没有接触过的问题,所以我不会当时就commit the ddl, 但我会告知product owner我需要跟tech leader商讨后确认是否可行以及项目要的复杂情况后会get back to him ASAP
* Task: 我需要在短时间内找到一个可实行的计划, 从而保证项目正常推进
* Action: 
    * 首先, 我会跟technical leader咨询组内是否进行过类似项目,并且基于我当时对项目的理解列出项目的主要功能, 可能需要的技术, 以及可能遇到的困难以及我的方案. 并跟Tach leader达成一致
    * 在我开始做项目之前, 我会back to manager, 跟他确认是否我现在理解的deliverable是他要的,并且跟他说明可能需要的开发时长
    * 我认为这样做, 一来不会错误理解项目, 二来也梳理出来了项目开发的具体逻辑以便于后续的开发
* This experience taught me the importance of good communication and collaboration

* Situation: During last 5 years in IBM, manager may gave me with unfamiliar issues.
* Task: My task is to come up with a feasible plan quickly to ensure the project progresses smoothly.
* Actions:
    * First, I will ask the manager a few questions: how important is this new project, the deadline of this new project, and preferred timeline
    * Then, I will consult with technical leader to see if our team has done the similar projects before.
    * After that, I will list the main features of new project, tech stack, potential challenges, and my proposed solutions based on my understanding of the project.
    * Before diving into the project, I circle back to the manager to confirm if my understanding of the deliverables aligns with their expectations.
* Result: I believe this approach will prevent misunderstandings about the project, and ensures that the project moves forward smoothly.


## In what you have learned so far about this role, do you have additional question you'd like to ask.
根据公司不同, 做出不同回答


## Tell me about a time you disagreed with a colleague or boss. What is the process you used to work it out?
* Situation: product owner认为更换新的UI design system可以提高用户体验, 在讨论如何更新前端框架时, 我与另外一个developer产生了技术选择方面的分歧.
* Task: 我认为我们不应该将所有JSF markup替换为react component, 因为这么做会超出预定的开发时间, 而他认为这是一个很好的机会去更新前端框架.
* Action:
    * 在与technical leader讨论后, 我们决定尝试将几个页面替换为react.
    * 尝试替换后, 我们发现这样做不仅要修改前端, 还要修改后端代码
    * 如果全部替换, 可能需要更长的开发时间, 并可能产生意料之外的问题
* Result: 最后我们选择替换页面逻辑并不复杂的页面, 对于页面十分复杂的页面, 我们选择只替换CSS styles, 从而保证页面风格一致
 

## When do you think it's ok to push back or say no to an unreasonable customer request?
* Situation: 在最近的项目中, 客户希望将部分数据移除, 从而方便客户进行更快速的检索和操作
* Task: 作为一个developer我认为,删除数据是一个不可撤销的操作, 用户可能并不了解后端如何保存数据, 所以该需求很可能会影响系统后续的运行
* Action:
    * 与数据团队沟通后, 我们发现需要移除的数据与其他数据共享一部分信息, 因此删除数据存在数据连贯性风险.
    * 因此我们再次与客户进行沟通, 并提出了新的解决方案: 在网页上设计一个dropdown menu, 允许用户将这一部分的数据隐藏起来, 用户表示同意
* Result: 最终, 该方案不光满足了客户的需求, 还没有破坏数据的完整性

* Situation: In a recent project, the client wanted to remove some data to make it easier for them to search and operate more quickly.
* Task: As a developer, I thought deleting data was a risky move since it's irreversible. Users might not know how the backend handles data storage, so this request could potentially mess up the system.
* Action:
    * After talking with the data team, we found out that the data to be removed shared some info with other data, so deleting it could mess up data consistency.
    * So, we went back to the client and suggested a new solution: designing a dropdown menu on the webpage to allow users to hide that part of the data. The users agreed.
* Result: In the end, this solution not only met the client's needs but also didn't mess with the integrity of the data.


## Agile Development
Follow the scaled agile framework:
* Product owner: define and plan the requirement for the work in next two month, define the priority of each ticket
* scrum leader: take care of tracking metrics, write the description of each ticket, use Kanban board as visual tool that helps team manage project tasks, workflows, and communication
* QA test team
* developer

* Project: 4 two weeks sprint, scrum team have the freedom to pick up what I want to work
* standup meeting with team for reviewing the active sprint twice per week, discuss about the progress or block of each ticket
* I will write the detailed block and issue under each ticket, I can review that if I meet the samiliar problem



### 如何确保代码质量

