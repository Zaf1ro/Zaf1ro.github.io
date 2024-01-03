---
title: Context Mapping
abbrlink: 7dc1
date: 2021-02-23 14:44:12
tags:
  - Microservices
category:
  - Microservices
keywords:
description:
---

## 1. Why use Context Mapping
Context不仅作为语义边界, 还作为团队边界. 那么不同的BC之间的关系如何表示, 这就需要用到**Context Mapping**. 以下是几个使用Context Mapping的原因:
* 逐渐复杂的Domain Knowledge让BC需要重新调整
* 组织架构的复杂度提升
* 团队数量和规模提升
* 跨地区/跨时区的团队合作
* 与外部依赖的整合
* 与Legacy system系统整合


## 2. Context Mapping Patterns
在介绍各种Pattern前, 需要先确定依赖表达的方式, 以下图为例:
![Downstream and Upstream in Context Mapping](/images/microservice/context-mapping-1.png)

在Context Mapping中, 我们用Upstream和Downstream来表示两个BC间的关系. **Downstream依赖于Upstream**. 之所以不使用箭头, 是因为箭头很容易被误认为成数据流, 而不是依赖关系. 因此, 上图的依赖关系为:
* B和C依赖于A
* C依赖于B


### 2.1 Shared Kernel
若两个Bounded Context共用一个domain model, 可以将共用部分提取出来, 称为**Shared Kernel**(共用内核):
![Shared Kernel](/images/microservice/context-mapping-2-1.png)

这种做法有好有坏: 好处是避免重复开发, 从而提高开发效率; 坏处是对Shared Kernel的高度依赖不利于未来拓展. 因此使用该pattern时需要注意一下几点:
* Kernel应边界明确且尽量小
* 所有使用该Kernel的团队都应在修改kernel前与其他团队商议
* 修改Kernel后应对两边BC都进行测试

例如: Shopping Context和Financial Analysis共享Order Model, 在Order Model分别放在两个BC中并没有任何好处, 因此可考虑Shared Kernel


### 2.2 Partnership
若两个Bounded Context要么一起成功, 要么一起失败, 且两边需要相互协作制定开发方案, 则可使用**Partnership**(合作关系):
![Partnership](/images/microservice/context-mapping-2-2.png)

注意, 该pattern并没有上下游关系, 而是互相依赖.


### 2.3 Anti-corruption Layer
**Anti-corruption Layer**(防腐层)是一种在不同BC之间转换概念或数据的pattern, 这样做可以防止BC的domain model收到外部污染. 其具有以下特点:
* 可为单向或双向
* 可作为一组service
* 可利用FACADE模式来隐藏复杂的转换逻辑, 以此避免BC受污染
* 仅包含转换逻辑, 不包含业务逻辑

其中最常见的就是场景就是legacy system. 当面对legacy system时, 如果没有时间和精力去重构, 可以为其包裹一层ACL, 达到不影响当前功能下也能开发新功能的效果.
![Anti-corruption Layer](/images/microservice/context-mapping-2-3.png)

例如: 当面对多个外部系统时, 每个外部系统的数据涵义不相同. 这时可以在BC外部加上一层ACL, 用于翻译数据.


### 2.4 Separate Way
若两个Bounded Context因技术, 沟通或地理原因导致合作成本过高时, 可考虑切断两者的关系, 称为**Separate Way**(另谋他路). 当然, 这也不意味着两个BC丝毫没有关系, 仍有可能透过UI或手动模式来整合.
例如: 通常Order和Shipping合作, 这样消费者可以从Order页面查询物流信息. 但随着第三方物流公司的加入, Order Context很难整合这些外部依赖, 可选择将物流查询链接交给用户, 让用户去点击查询.


### 2.5 Open Host Service/Published Language
Open Host Service(开发主机服务, 简称OHS)意为上游BC制定一份protocol(协议)并公开, 让下游通过协议使用上游服务, 用于上游对接多个下游的情况. 与其在每个下游都创建一个ACL, 不如在上游创建一个OHS. 在使用OHS时, 一般会搭配Published Language(发布语言, 简称PL). OHS用于定义协议, PL作为传输数据的格式, 如XML, JSON, Protocol Buffer等.
![Open Host Service/Published Language](/images/microservice/context-mapping-2-4.png)


### 2.6 Big Ball of Mud
当我们检查已有系统时, 经常会发现系统中存在混杂在一起的模型, 它们之间的边界是非常模糊的. 此时应为这些BC划定一个边界, 并将其归纳入一个**Big Ball of Mud**(大泥球)中. 在这个边界之内, 不要试图使用复杂的建模手段来化解问题. 同时, 这样的系统有可能会向其他系统蔓延, 应对此保持警觉. 在串联Big Ball of Mud时, 可考虑加上ACL充当翻译角色.


### 2.7 Customer-Supplier
若某个Bounded Context与其他BC存在上下游关系时, 上游可独立于下游完成开发, 而下游必须受限于上游方的开发计划, 则采用Customer-Supplier(客户-供应商). 当上游开会做出决策时, 下游也需被通知, 甚至一起参加会议. 这时就很容易产生下游被上游限制的情况, 如果发生在跨公司团队之间, 则会导致开发效率底下.
![Customer-Supplier](/images/microservice/context-mapping-2-5.png)

其中一种解决方案是让上游将下游视为"客户", 下游提出需求和预算, 双方共同制定**Automated Acceptance Tests**(自动化验收测试)以验证预期的效果. 只要上游修改后的代码能通过测试, 则可以放心地交给下游使用. 也可以在下游建立ACL以用于转换model. 该pattern适用于修改成本较小的BC使用.


### 2.8 Conformist
同样是Bounded Context或团队间存在上下游关系时使用, 但此时上游没有满足下游的需求, 称为**Conformist**(遵奉者). 常见于大公司的两个部门之间, 跨公司合作, 或与系统内没人能完全懂的Legacy system建立联系.
![Conformist](/images/microservice/context-mapping-2-6.png)

一般来说, 当与外部系统的整合成本太高时, 会采用三种方案:
* 上游依赖成本过高, 采用Separate Way
* 上游有一定依赖价值, 但设计有缺陷(文件, 封装, 抽象存在问题), 考虑加ACL
* 上游有一定依赖价值, 且设计不算差, 可考虑Conformist

在Conformist的环境下, 下游Model完全受制于上游, 两者很容易产生强耦合. 


## 3. E-commerce Bounded Context
以下是E-commerce的业务逻辑:
* **Purchase**(结账)时判断**Identity**(会员)等级, 若是会员则会有折扣
* **Catalog**(浏览商品)时, 部分商品只能被特定**Identity**(会员)等级的用户看到
* **Purchase**(结账)时需从**Catalog**(商品目录)取得商品信息来计算价格
* **Purchase**(结账)时需要通过**External Payment**(第三方支付)来处理支付
* 整合**External Shippment**(第三方物流)让用户知道货物物流信息
* **Revenue**(营收分析系统)需要与**Purchase**(购物系统)共享资料

以下是一种Context Mapping的示例图:
![E-commerce Context Mapping](/images/microservice/context-mapping-3-1.png)
