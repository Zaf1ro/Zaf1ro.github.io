---
title: Domain, Subdomain, and Bounded Context
abbrlink: 5a33
date: 2021-01-04 16:53:21
tags:
  - Microservices
category:
  - Microservices
keywords:
description:
---

## 1. What is domain
上一篇文章讲了DDD的设计初衷, 组成部分, 路线图, 但始终没有解释什么是**domain**. Domain在字典中翻译为: 感兴趣的领域, 或人们能够控制的领域. 这么说可能还是有些模糊, 以下图为例, 如何为以下图像分类:
![How to group these concepts into domains](/images/microservice/domain-and-bc-1.1.jpeg)

不同的人面对上图可能有不同的想法, 有些人根据形状分类, 有些人通过颜色分类, 还有一些人根据其他方式分类:
![The same concepts can belong to different domains](/images/microservice/domain-and-bc-1.2.jpeg)

上图中第一组根据Shape(形状)分类, 因此是**Shape Domain**, 因为其关注点为Shape; 第二组根据Color(颜色)分类, 因此是**Color Domain**; 因此, Domain就是工作所面对的**问题**和**解法**.


## 2. Problem Space and Solution Space
对于真实业务, 每个组织都有自己的独特的业务范围与解决方式, 而工作中遇到的**问题**和**解法**就是domain的组成. 在传统开发流程中, 会将问题与解法分离, 业务团队负责提出问题和规格, 开发团队负责解决和维护. 以下是两者之间可能存在的映射关系:
![Mapping between Problem and Solution](/images/microservice/domain-and-bc-1.png)

随着业务逻辑复杂度不断提升, 在缺乏交流和规范的情况下, 业务团队与开发团队的沟通成本不断加重. 一旦业务团队没有表达清楚需求, 或是缺乏从整体的角度去思考问题, 则产品很容易出问题. 而面对突然冒出的需求, 开发者通常只能利用当前架构修修补补, 且很难应对未来需求的变化. DDD的做法则不同, 它将**问题**和**解法**结合在一起, 以下是一个简单的例子:
![Mapping between Problem and Solution](/images/microservice/domain-and-bc-1.3.jpeg)

可以看到, 项目中含有三个domain, 分别具有自己的Problem Space和Solution Space. 这也需要业务团队与开发团队更多的沟通, 让开发人员对于需求有更深刻的了解.


## 3. Subdomain
定义完domain后, 开发者可能想创建一个domain model来实现domain的所有功能. 但实际上, domain的problem space还可以继续分解, 称为subdomain(子域). Subdomain根据优先级, 功能性, 替代性分为以下三种类型:
* Core Doamin(核心域): 整个domain中最重要的, 也是最耗时开发的, 例如: 商品推荐需求
* Supporting Subdomain(支持域): 支援core domain的附属功能, 且没有现成方案可以套用, 例如: 购物需求
* Generic subdomain(通用域): core domain和supporting subdomain都用到的功能, 也可以包含外部依赖, 例如: 身份认证需求

三种subdomain的关系可类比为下图:
![Core Domain, Supporting Domain, and Generic Subdomain](/images/microservice/domain-and-bc-1.4.png)

总结一下, subdomain可以当做某个domain中的domain, subdomain拥有和domain相同的定义. 但请注意, 我们一直没有提到solution space. 所有的subdomain都是围绕着拆解problem space而展开. Subdomain自身也可以被继续拆分成多个subdomain, 形成多层嵌套的domain:
![Domains are hierarchical and they represent business capabilities](/images/microservice/domain-and-bc-1.5.jpeg)


## 4. Bounded Context
Bounded Context为Solution Space的Domain Model建立一个语意边界, 让domain mode在数据和行为上都能符合Ubiquitous Language和业务需求. 其定义可以解释为: 一个可以让单词或句子获得完整意义的环境. 举个例子, 当我们形容国家首脑时, 需要考虑"国家"这个上下文: 对于美国是"总统", 对于英国是"首相", 对于德国是"总理". 一个solution space包含一个或多个BC.
对于软件开发来说, 当开发者根据不断迭代的需求往系统中添加功能时, 每个需求其实都有自己的BC, 同一名词在不同的BC下存在不同的定义. 以下图为例, Account在Bank BC下是关于资产管理, 在Social BC中是关于好友管理, 在Blog BC下是关于文章管理. 如果Account被三个系统共用, 每个系统的开发者都将面对一个巨大且杂乱的Account.
![Bounded Context](/images/microservice/domain-and-bc-1.6.png)

因此每个BC都应有自己的一套Ubiquitous Language, 这样就不会在开发Blog Account时需要考虑Social Account的资料, 也不用担心影响到Bank Account. 


## 5. Difference Between Subdomain and Bounded Context
Subdomain是对业务需求的拆分与分类; Bounded Context是对解决方案的拆解和分类. 两者紧密相连也很容易搞混, 就像是地板和地毯的关系. Subdomain是地板, Bounded Context是地毯. 当你装修完时, 需要保证地板和地毯完全匹配; 当某天需要换地毯时, 会发现新地毯无法百分之百匹配, 甚至会被家具(Legacy System)挡住, 这时两者的差异才会显现出来.


## 6. E-Commerce Example
以电商为例, 电商可能的需求如下:
* Product Catalog: 商品目录
* Order: 订单
* Payment: 支付
* Shipping: 物流
* Invoice: 发票
* Inventory: 仓库
* Forecast: 推荐

在使用Strategic Design前, 项目规划可能如下:
![A Domain with Subdomains and Bounded Contexts](/images/microservice/domain-and-bc-1.7.png)

上图中, 虚线表示subdomain的边界, 实线表示系统的边界. 这其中有几点问题:
* E-Commerce system承担了太多责任
* 没有业务重点被划出来
* 难以修改或新增其他功能

在应用Strategic Design时, 需要先为subdomain分类:
* Core domain: Optimal Acquisition(优化购物体验需求, 如推荐系统)
* Supporting domain: Purchasing(购物需求)
* Supporting Subdomain: Inventory(仓储需求)
* Generic Subdomain: Resource Planning(其他资源管理请求)

以此作为Bounded Context的边界, 新的软件架构如下:
![The Core Domain and other Subdomains involved in purchasing and inventory](/images/microservice/domain-and-bc-1.8.png)
