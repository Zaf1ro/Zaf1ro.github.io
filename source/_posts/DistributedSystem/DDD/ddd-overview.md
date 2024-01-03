---
title: DDD Overview
tags:
  - Microservices
category:
  - Microservices
abbrlink: aaa9
date: 2021-01-02 09:10:18
keywords:
description:
---

## 1. Definition of DDD
DDD(Domain-driven design)作为一种概念, 主张将软件代码中的结构和语言(class name, class method, class variable)与business domain(业务领域)相结合. 举个例子, 若一个应用用于处理贷款, 那么它可能包含名为**LoadApplication**和**Customer**的class, 还有名为**AcceptOffer**和**Withdraw**的method. DDD的设计基于以下几个目标:
* 将项目中的重点放在core domain和domain logic
* 根据domain model进行复杂设计
* 让技术专家和domain expert开始创造性工作, 以迭代方式提炼出一个概念上的model, 并借此解决特定领域问题

以下是DDD pattern的全貌:
![Ovew of DDD](/images/microservice/ddd-overview-1.jpg)

DDD主要分为两部分:
* Strategic Design(战略设计): 将domain拆分成多个subdomain, 目标是为了定义Bounded Context, Ubiquitous Language和Context Maps.
* Tactical Design(战术设计): 其中包含很多用于构建domain model的技术资源, 例如: entity, value object, aggregate, service, repository, factory, event, module. 这些技术被运用在单个Bounded Context中.


## 2. Strategic Design
DDD的的strategic design目的在于协助开发者捕获并获得e**Domain Knowledgee**(领域知识), 并将其拆分成适当的大小以便后续分析处理. 整个strategic design可分为以下几点:
* 与domain expert沟通, 捕获domain knowledge并构建**Ubiquitous Language**(通用语言)
* 依照所理解的**Problem Space**(问题域)以及**Solution Space**(解决方案域)来建立**Domain**(领域)
  * Problem Space: 代表domain关注的问题, 可拆分为多个Subdomain
  * Solution Space: 代表doamin的解决方案, 可开发多个domain model来解决问题, domain model需要被隔离在Bounded Context中保证Model与Ubiquitous Language一致
* Subdomain根据优先级分为多个类型:
  * Core Doamin
  * Supporting Subdomain
  * Generic Subdomain
* 遵循Ubiquitous Language将Solution Space分成一个个语义边界, 称为**Bounded Context**(限界上下文, 简称BC)
* 使用**Context Mapping**(上下文地图)定义多个BC之间的关系

BC(Bounded Context)作为概念上的边界, 适用于domain model. 每个BC都有自己的Ubiquitous Language, 用于组内开发者沟通和展示软件模块, 如下图:
![A diagram illustrating a Bounded Context and relevant Ubiquitous Language](/images/microservice/ddd-overview-2.png)

当我们使用Strategic Design时, 会发现**Context Mapping**是一种很好的模式, 以便清晰地辨别各个BC之间的关系:
![Context Maps show the relationships among Bounded Contexts](/images/microservice/ddd-overview-3.png)


## 3. Ubiquitous Language
由于现代软件开发的复杂度越来越高, 没有一个开发者可以掌握团队中所有业务细节, 甚至连domain expert都可能有所疏漏. 为了在开发过程中, 我们需要对业务中的知识建立共识, 建立Ubiquitous Language来减少沟通和理解成本. 简单说, Ubiquitous Language可以作为一套domain内描述业务概念的用词表, 可用于团队沟通, 文档, 和代码中.
例如: 当我们描述使用服务的"客户"时, 不同的开发者面对不同的业务, 可能有以下几种称呼:
* user
* buyer
* consumer
* client
* ....

如果放任团队中的每个人使用不同的名称, 那么无论是沟通, 还是代码实现中, 都会出现分歧. 无论对于domain expert和开发团队的沟通, 不同开发者间的沟通, 还是后续开发者的接手, 都是一种障碍. Domain expert和技术团队应建立一种Ubiquitous Language, 让所有业务知识都有统一且明确的名称和涵义, 如下图:
![Glossary - Ubiquitous Language](/images/microservice/ddd-overview-7.png)


## 4. Tactical Design
Tactical design可以帮助开发者运用一些成熟的design pattern, 将strategic design的成果以代码形式实现, 以下是用到的一些design pattern:
* Entity(实体): 能被辨别出来的物体, 自身带有id. Entity的状态会在其生命周期中不断变化.
* Value Object(值对象): 无identity概念, 状态不可变的对象, 用于描述某个事物的特征.
* Aggregate(聚合): 多个对象组成的集合, 包含entity和value object(其中一个entity作为aggregate root, 所有与aggregate外部的交流都由aggregate root负责). 一个aggregate即一个transaction的边界. 

上述三个负责domain的业务逻辑, 因此也被称为domain object(领域对象).
* Repository(仓库): 用于持久化domain object, 可以转接ORM或File system. 通常一个aggregate对应一个repository. 以下是一个示例图:
![Two Aggregate types with their own transactional consistency boundaries](/images/microservice/ddd-overview-4.png)

* Factory(工厂): 与**Design Patterns: Elements of Reusable Object-Oriented Software**一书中的Factory pattern相同, 在DDD中用于处理aggregate生成的复杂场景.
* Domain event(领域): 表示domain中发生的事件, 用于多个aggregate之间的沟通. 当aggregate做出某些操作后, 可以发布domain event, 如下图:

* Domain service(领域服务): 当某个business logic无法被安排到任何一个domain object时, 会由domain service负责, 如下图:
![Domain Services carry out domain-specific operations, which may involve multiple domain objects](/images/microservice/ddd-overview-5.png)

* Application Service(应用服务): 负责处理请求, 调用domain object和domain service以处理业务逻辑
![Domain Events can be published by Aggregates](/images/microservice/ddd-overview-6.png)

以下是DDD的学习路线图:
![Roadmap of Domain-Driven Design](/images/microservice/ddd-overview-10.png)


## 5. Anemic pattern
该anti-pattern设计下的class有以下特征:
* 乍看上去像是一个真实存在的物品抽象, 其中包含一些object(对象), 对象名称是有意义的, 这些对象也具有紧密关系
* 对象几乎没有什么行为, 只有一些简单的getter和setter

其中一些ORM工具如Hibernate. Entity Framework更是助长了anemic pattern的扩散. 当使用anemic model时, 看似是面向对象编程(使用到class, 且class中有紧密相关的数据与操作函数), 但实际上只是对数据进行简单的封装, 本质上仍然是**面向过程**. 这种模式设计下的class对象功能贫乏, 就像贫血一样, 因此称为anemic pattern. 当上层调用这种pattern的对象时, 很容易写出transaction script(事务脚本), 导致开发效率低下, 维护成本巨大, 如下:
```java
customer = new Customer('Bill');
order = Order.create(customer, 'Coffee');
staff = new Staff(9527);
cashier = new Cashier();

// 结账
order.setStaff(staff);
staff.setCashier(cashier);
staff.setOrders(order);
cashier.addOrder(order);

// 泡咖啡
cup = new Cup();
staff.setCup();
cup.setFilterCone(new FilterCone());
cup.setCoffeeGround(new Coffee());
staff.brew(cup);
staff.wait();
staff.setFilterCone(null);

// 送餐
staff.setCoffeeTo(customer);
customer.setCoffee(order);
```
通过DDD设计后, 与domain expert沟通并形成Ubiquitous Language后, 可让代码修改如下:
```java
barista = new Barista(9527);
customer = new Customer('Bill');
order = customer.placeOrder(order);

barista.processPayment(order);
barista.make(order);
barista.serveOrderTo(order, customer);
```

## Pro of DDD
以下是DDD的优点:
* 促进跨团队沟通, 深入理解领域知识
* 专注于核心业务上
* 保证业务逻辑不会因外部依赖的更改而影响
* 更好的模块化
* 更容易测试
* 更容易迭代和维护

以下是DDD不适合的项目类型:
* 项目中没有domain expert
* 项目没有多余的沟通时间和学习成本
* 项目的业务逻辑较为简单
* 项目的业务逻辑几乎不发生变化
