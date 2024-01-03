---
title: DDD and CQRS Pattern (2)
tags:
  - Microservices
category:
  - Microservices
abbrlink: dd44
date: 2021-02-11 11:04:03
keywords:
description:
---

## 1. Design a DDD-oriented microservice
DDD(Domain-driven design)提倡基于业务逻辑的建模. 在构建程序时, DDD会用domain来描述问题. 每一个独立的问题域作为一个BCs(Bounded Contexts, 每一个BCs关联一个microservices), 并强调使用一种通用语言来讨论问题. DDD还提出了一些其他概念和模式来帮助实现, 例如: domain entities with rich models, value objects, aggregates, aggregate root.
由于DDD的学习曲线比较陡峭, DDD有时会被认为是一个障碍. 其难点并非在于pattern本身, 而是如何根据业务问题组织代码, 并使用通用语言. 此外, 只有在实现重要业务规则的复杂microservices时才会用到DDD, 较为简单的功能可以通过CURD或其他方法来实现.
当设计一个microservices时, 重点在于如何划分各个microservices的边界. 借助DDD可以理解domain中的复杂性. 对于每个BCs的domain model, 我们需要确定并定义entities, value objects和aggregates, 以此来为domain建模. 在边界中创建并优化的domain model用于定义其context, 对于microservices来说尤为明显, 边界中的component最终会构成microservices, 但在某些情况下, BC或business microservices可由多个物理服务组成. DDD和microservice都与边界有关.

## 2. Keep the microservice context boundaries relatively small
不同BCs之间边界的决定来自于两个相互矛盾的目标:
1. 创造尽可能小的microservices
2. 避免多个microservices之间有过多的通信

开发者应不断地缩小每个microservices的边界, 直到microservices之间的通信次数因边界划分而激增. Cohesion是单个BC的关键. 若两个microservices总需要和对方合作, 则它们应合并为一个microservices. 另一个考量方式是autonomy(自治权), 若一个microservices必须依赖另一个microservices才能处理请求, 则该microservice并不具备autonomy.

## 3. Layers in DDD microservices
大多数业务和技术较为复杂的项目都由多个layer定义, layer是一个逻辑上的概念, 与服务的部署无关. Layer的存在是为了帮助开发者更好的管理代码的复杂度, 不同的layer有不同的类型, 不同类型之间需要翻译.
举个例子, entity从数据库中加载. entity的部分信息, 或与其他entity组成的信息可以被REST Web API发送到client UI. 重点在于, domain entity限定在domain model中, 不应传播到其他区域(例如: presentation layer).
此外, 我们始终需要通过aggregate root控制的始终有效的entity. 因此, entity不应和client view绑定, 因为UI层面上, 很多数据是没有验证过的, 这也是使用ViewModel的原因之一: ViewModel是专门为presentation layer创建的数据模型, ViewMode和domain entity之间需要相互转换.
为解决复杂性, 我们需要一个aggregate root来控制一个domain model, 以保证一组entity(aggregate)的所有相关规则和常量都由该单一入口(aggregate root)执行.
![DDD layers in the ordering microservice in eShopOnContainers](/images/DDD/2-1.png)

上图将订单系统的DDD microservices分为三层, 每一层都是一个VS project:
* Application Layer: Ordering.API
* Domain Layer: Ordering.Domain
* Infrastructure Layer: Ordering.Infrastructure

我们需要让每一层只跟特定的其他层通信, 一个简单的方法就是将不同的层定义在不同的class library中, 因为这样开发者可以更清晰地确定层之间的依赖关系. 举个例子, domain layer不应依赖于其它层, 只应包含Plain Old CLR Object, POCO或class. 如下图所示, **Ording.Domain**只依赖.Net library和NuGet package.
![Layers implemented as libraries allow better control of dependencies between layers](/images/DDD/2-2.png)

## 4. The domain model layer
该层负责表示业务概念, 有关业务状况的信息和业务规则. 反映业务状况的状态通过这一层进行控制和利用, 但有关状态存储的技术细节则由infrastructure layer负责, 这一层是业务软件的核心.
Domain model layer就是业务表达的地方, 当使用.NET来实现microservices domain model layer时, 该layer作为包含domain entity的class library, 用于捕获数据和行为.
遵循**Persistence Ignorance**和**Infrastructure Ignorance**原则, 该层必须忽略数据持久性细节, 由infrastructure layer来实现持久性任务, 因此该层不应直接依赖于infrastructure, 也意味着domain model entity class应为POCO(Plain old CLR object).
Domain entity不应直接依赖任何data access infrastructure framework, 例如: Entity Framework或NHibernate. 理想情况下, domain entity不应继承或实现任何infrastructure framework中的类型.

## 5. The application layer
该层定义了软件需要做的任务, 并指导domain object去解决问题. 该层负责的任务要么对业务很有意义, 要么负责与其他系统的application layer进行交互. 该层很"薄", 不会包含业务规则, 仅用于协调, 分配工作给下一层中domain entity. 该层不具有反应业务状况的状态, 但可以反映用户或程序的任务进度.
.NET中microservice的application layer通常被编码为ASP.NET Core Web API project. 该项目实现了microservices的交互, 远程网络访问, client app所需要外部Web API. 该层包含query(如果使用CQRS方法), microservices接受的command, 甚至是microservices之间的事件驱动通信. 该层不能包含业务规则或domain knowledge. 业务规则和domain knowledge应由domain model掌握, application layer只能协调任务, 不能定义或包含domain state. 它将业务规则的执行委托给domain model, 最终在domain entity中更新数据.
基本上, 该层的实现基于前端. Domain model layer中的domain logic, 其data model和业务规则必须完全独立于application layer, 且不能依赖于任何其他infrastructure framework.

## 6. The infrastructure layer
该层是关于domain entity中的数据如何持久化到数据库中. 为遵循**Persistence Ignorance**和**Infrastructure Ignorance**原则, 该层不能"污染"domain model layer. Domain model entity对于该层是不可知的. 以下是三层结构的依赖图:
![Dependencies between layers in DDD](/images/DDD/2-3.png)

DDD服务中, application layer依赖于其他两层, infrastructure layer依赖于domain model layer, 但domain model layer不依赖任何其他层. 

## 7. The Domain Entity pattern
我们的目标是为每个BC创建一个domain model. 一个BC可能由多个物理服务组成, domain model必须包含规则, 行为, 业务语言和约束. Entity表示domain object, 通常由identity(标示), continuity(连续性)和persistence(持久性)所决定, 而不光是由属性决定. Entity在domain model中很重要, 因为它是model的基础, 因此需要仔细识别和设计. 
Entity的identity可横跨多个BC. 但这并不意味着在多个BC中会出现一个拥有相同属性和逻辑的同一entity. 相反, 在不同BC的限制下, entity会拥有不同的属性和行为. 举个例子, 在profile或identity microservices中, buyer entity可能拥有user entity的很多用户属性; 但buyer entity在ordering microservices中有更少的属性, 因为buyer中的数据只有少部分和order处理有关. microservice或BC的上下文影响着domain model.
除了属性外, domain entity还需要实现behavior(行为). DDD中的Domain entity必须实现与entity data相关的domain logic或行为. 举个例子, order entity必须实现业务逻辑和操作的函数, 例如: 添加order, 数据验证, 总计算. Entity method负责处理entity中的常量和规则, 而不是将这些规则分布在application layer.
![Example of a domain entity design implementing data plus behavior](/images/DDD/2-4.png)

Domain model entity通过**函数**来实现**行为**, 即该model不是anemic(贫血) model. 有时entity不会实现任何行为, 例如: child entity中可能不包含任何函数, 因为所有行为都定义在aggregate root中. 如果有一个复杂的microservice, 它在service class中实现了行为, 而不是在domain entity中, 那么该domain model为anemic model.

## 8. Rich domain model vs anemic domain model
Anemic domain最重要的特征是: 乍一看上去是一个真实存在的物品, 包含一些object(对象), 很多以domain space中的名词命名, 这些对象具有紧密关系, 结构上与真实的domain model相同; 但当我们观察其行为时, 这些对象几乎没有什么行为, 只有一些简单的getter和setter.
当使用anemic model时, 这些data model会被service object(business layer)使用, 这些service object负责业务逻辑. business layer位于data model之上, 就像使用数据一样使用data model.
Anemic model只是一种程序化样式设计, 并不是真实的对象, 因为其缺乏行为(方法). 该model只是具有一些属性, 并不是一种面向对象的设计. 将所有业务逻辑放入business layer, 最终会导致spaghetti code或transaction scripts, 从而失去domain model的优势.
如果microservice或BC十分简单, 仅包含属性的anemic domain model就已经足够了, 没必要实现更复杂的DDD pattern. 这就是为什么microservice可以根据不同的BC来使用不同的体系结构. 例如, 在ordering microservice中使用DDD pattern, 而在catalog microservice中使用CRUD service.

## 9. The Value Object pattern
很多对象没有一个概念上的identity, 这些对象只是描述事物的特征. Entity需要identity, 但系统中很多对象并不需要identity, 例如value pattern. Value object是一种没有identity的对象, 用于描述domain aspect. 这些对象实例化后可表示短期需要的一些设计元素. 开发者只关心它们是什么, 而不关心他们是谁, 例如数字和字符串; 也可能是一些更高级的概念, 例如属性组.
一个microservice中的entity在另一个microservice中可能就不是entity, 例如: 电商应用的**地址**可能没有identity, 因为它仅表示个人或公司的的客户资料的一组属性, 这时**地址**应归类为value object; 但在电力公司的应用中, **客户地址**对于业务很重要, 因此该地址需要identity, 以便计费系统能直接链接到该地址, 这种情况下**地址**应归为entity. 有姓名的人通常也是一个实体, 因为这个人有identity, 即使与其他人同名同姓, 也可通过identity进行区分.
Value object在关系型数据库和ORM中很难管理, 而对于文档数据库就很容易实现.
