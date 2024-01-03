---
title: Bounded Context
abbrlink: a06c
date: 2021-02-22 20:54:32
tags:
  - Microservices
category:
  - Microservices
keywords:
description:
---

## 1. How to Identify Bounded Context
Bounded Context的好处很明显, 为domain划清边界, 并在内部建立自己的Ubiquitous Language, 让domain model中的属性与其上下文一致. 但问题也很明显: 如何找到每个domain的Bounded Context. 下面是一个已经划分好的BC.
![A divided bounded context](/images/microservice/bounded-context-1.png)

很多项目中可能没有那么多时间深入探讨domain knowledge, 但这并意味着我们应该彻底忽略业务层面的抽象. 如果混淆了Operational Level(操作层)与Knowledge Level(知识层), 就缺乏业务规则模型的抽象, 从而导致代码腐化, 团队沟通和代码维护成本不断增加. 通常来说, 划分BC需要系统分析和业务能力, 但如果团队中没有domain expert或面对陌生的业务, 可以从以下两点出发: 
* Linguistic(语意)
* Business Capability(业务能力)


## 2. Linguistic
在Bounded Context中, 我们用Ubiquitous Language命名各种概念的实体, 因此BC本质上是一个语意边界. 当对某个实体设置不同的定义时, 我们就需要一个新的BC, 以此保证BC中的语意保持一致.
当需求有所改变时, 也需要重新审视Bounded Context之间的匹配程度. 如果新实体符合某个BC中的Ubiquitous Language, 则加入到该BC中; 如果不符合, 则需要建立新的BC. 以下是语意划分BC的三点总结:
* 注意经常出现的词汇和句子
* 注意拥有相似概念或名称, 但在不同语境下存在歧义的词汇和句子
* 当某个BC经常使用其他BC的语言时, 需要考虑其必要性, 可能需要合并BC


## 3. Business Capability
刚开始划分BC时很容易陷入一个误区: 按照**实体**去决定BC. 例如: 按照顾客, 订单, 商品等名词来划分. 上述例子犯了一个错误: BC的划分不取决于数据模型, 而取决于**业务能力**. **用户**作为一个BC很容易被其他BC共享, 甚至会和ORM框架捆绑, 这都不符合DDD的思想, 也破坏了BC的一致性. 举个例子, 根据业务能力可以将项目划分为以下几个BC:
* Membership: 会员管理
* Order: 订单
* Shipping: 物流
* Payment: 支付

**用户**在每个BC有不同的含义, 例如:
* Membership中, **用户**可能包含名称, 个人资料, 会员等级, 会员点数
* Order中, **用户**可能包含买家名称
* Shipping中, **用户**可能包含联系地址, 电话号码
* Payment中, **用户**可能包含付款人信息

理想情况下, 每个BC对应一个subdomain; 但根据Business Capability划分BC, 可能导致BC跨越多个subdomain. 


## 4. Autonomy
通常好的系统都有Autonomy(自治性), 可减少彼此依赖. 这种依赖不仅是逻辑上的依赖, 该包含底层数据的依赖. 理想情况下, 我们希望每个系统都有自己的数据库, 保证不被外界污染. 因此, 当某个数据库不完全属于某个BC时, 可以考虑将其拆分出去.
举个例子, **购物**BC只需要处理购物服务, 对于**会员**功能, 由于其他系统也需要查询会员身份, 因此不应放置在**购物**这个BC中, 而应新增一个**身份管理**BC. 当**购物**BC需要查询身份时, 与**身份管理**BC沟通即可.


## 5. Keep the microservice context boundaries relatively small
Bounded Context作为天然边界, 可以用于microservice的划分. Microservice的目标是通过组件化服务来支持大型且复杂的系统. 但microservice的划分并不是越小越好, 这之间存在两个相互矛盾的目标:
1. 创造尽可能小的microservices, 增加可维护性和开发效率
2. 避免多个microservices之间有过多的通信, 提高程序运行效率

开发者应不断地缩小每个microservices的边界, 直到microservices之间的通信成本超过了某个限度. Cohesion是单个BC的关键. 若两个microservices总需要和对方合作, 则它们应合并为一个microservices. 另一个考量方式是autonomy(自治权), 若一个microservices必须依赖另一个microservices才能处理请求, 则该microservice并不具备autonomy.


## 6. Conway Laws
根据**Conway Laws**, 软件系统的架构应符合开发团队的架构. 对于Legacy system, 若该系统已经难以维护, 且没有更多时间重构, 这是应将该系统独立为一个BC, 并建立多个Adapter去连接其他BC. 很多时候导入Bounded Context并没有获得预期效果, 问题可能出在组织架构上. 忽视开发团队的架构而去细分BC只会提高部门合作成本.
从某种角度来说, BC其实是开发组织的分工, 当组织越来越大时, 贴近BC的分工能让开发者能容易管理与合作. 从而减少团队间的依赖关系, 以达到更高的自治性.


## 7. Cinema Example
假设我们需要建立一个电影院系统, 具体需求如下:
* **Box Office**(售票处)可以售票给顾客, 同时检查顾客的**身份**, **时间**, **电影**, **座位**
* 与**Online Booking**(第三方订票网站)合作, 利用线上方式预订电影票
* **Auditorium**(放映厅)会在顾客进入前检查电影票
* 顾客可在售票处购买食物, 然后去**Concession Stand**(小卖部)领食物
* 小卖部还负责管理食物的库存, 少于50%时要及时补货

分析过后, 可以将整个业务分为三个主要需求: 售票, 观影, 食物. 其中**观影**是电影院的core domain, 其他的属于supporting subdomain.
![Cinema Subdomain](/images/microservice/bounded-context-7-1.png)

根据每个domain的情况, 分为以下几个Bounded Contexts:
* Box Office Context: 售票处
* Online Booking: 网上售票
* Concession Stand Context: 小卖部
* Inventory Context: 仓库
* Auditorium Context: 放映厅

![Cinema Bounded Context](/images/microservice/bounded-context-7-2.png)

可以看到, 很多bounded context都会用到**ticket**(电影票)这个实体. 一个电影票在不同的context中可能有不同行为:
![Ticket in Different Contexts](/images/microservice/bounded-context-7-3.png)


## 8. Summary
### 8.1 Size of Bounded Context
Bounded Context并没有一个固定的大小, 主要看语义和业务能力来判断. 在项目刚开始时, 业务逻辑相对简单, 通常不需要太多BC就可以完成所有需求; 但随着项目不断扩大, 会有越来越多的外部概念渗入BC, 从而导致迭代速度降低, 沟通成本增大.

### 8.2 Misunderstanding of BC
1. 从一开始划分BC, 之后再也不改动: 应随着项目复杂度的提升而不断划分BC, BC的划分不会一步到位
2. 根据技术划分BC: 比如说根据数据库划分, 根据外部依赖划分, 这些都不能决定BC的边界
3. 根据开发任务划分BC: 新的功能或需求并不能代表我们需要新增一个BC, 保持BC的语意一致性才是重心

## 8.3 Power of Bounded Context
* 概念不会混淆: 在BC的语意边界内调用服务时, 开发者很清楚自己在做什么. 例如: 当使用User这个名词时, 很容易弄不明白这到底代表什么, User可以表示客户, 或管理员, 或User系统.
* 分离业务功能: 当我们开发某个功能时, 很可能牵扯到另一个业务功能. 例如: 订单系统可能牵扯权限问题, 那么权限到底应该会放在哪里比较好. 以下是两种思路:
  1. 在所有需要判断的地方都放置判断语句
  2. 在一开始访问时判断, 之后不再验证

无论选择哪种处理方式, 都需要将权限判断作为一个单独的BC分离出来. 这样可以避免很多重复代码, 且维护成本更低.
