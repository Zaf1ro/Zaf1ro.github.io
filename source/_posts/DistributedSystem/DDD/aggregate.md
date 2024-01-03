---
title: Aggregate
abbrlink: c11b
date: 2021-05-01 15:21:34
tags:
  - Microservices
category:
  - Microservices
    - Domain-Driven Design
keywords:
description:
---

## 1. Overview
当Domain中的Entity和Value Object越来越多时, 各个模型之间的交互越来越复杂, 管理这些互动关系就变成一个问题. 因此需要设计一个边界来降低复杂度, 保持边界内规则的完整性, 称为aggregate. 以下是关于aggregate的几个问题:
* 如何处理模型间复杂的关联性
* 如何在模型中划分出边界
* 如何将关联性放入repository
* 使用repository模式时, 是否要给每个Entity建立一个Repository


## 2. State of Aggregation
在具有复杂关系的模型中, 想保证Strong consistency(强一致性)是很困难的. 例如, 当用户网购下单时, 一个订单会包含很多模型(商品, 折扣, 支付, 物流, 发票等), 若用户取消某个已下单的商品, 需重新计算折扣, 退款, 退货, 重新开发票, 甚至影响到会员系统或商品推荐系统.
因此需要Aggregate来降低复杂度, Aggregate是一群相关联模型(Entity或Value Object)的集合, 每个Aggregate需要有一个Entity作为**Aggregate Root**, 任何获取数据或修改数据都需要通过Aggregate Root, 再传给Aggregate中的其他模型. 以下是Order Aggregate的模型设计:
![Order Aggregate 1](/images/microservice/aggregate-1.png)

将Order Entity作为Aggregate Root, 无论外部有什么请求, 都要先经过Aggregate Root才能与Aggregate内部的其他模型互动. 这样Aggregate Root不仅可以封装业务逻辑, 还可以保证状态变化时, 规则保证一致性(Invariant), 模型如下:
![Order Aggregate 2](/images/microservice/aggregate-2.png)

对于Order Aggregate, 可能存在以下Invariant(固定规则):
* OrderItem(商品)的数量可以被增加, 减少, 但总数量不能为零
* Payment(支付)与OrderItem的数量相关
* Shipping(物流)有最低消费限制
* Invoice(发票)包含支付信息
* 退货时需要将商品重新放回Inventory

若开发者不采用Aggregate, 当用户修改订单中的商品数量时, 则需对多个模型进行更新:
1. OrderItem.update()
2. Payment.check()
3. Order.update()
4. Shipping.check()
5. Invoice.update()
5. Inventory.update()

如果使用Aggregate, 则整个过程更加简洁: Order.updateItem(), Inventory.update(). 其中Order.updateItem()既是状态改变的原因, 也是修改支付金额, 发票信息, 检查最低消费的结果. 由此保证业务的一致性.


## 3. Design Principles 
以下是Aggregate的几个设计原则:
* Aggregate Root的Entity必须在Bounded Context中有唯一标示
* Aggregate Root负责检查边界内的所有Invariants(固定规则)
* Aggregate外的物品不能引用除Aggregate Root之外的任何内部模型
* 通过Repository只能获得Aggregate Root, 不能获得Aggregate中的其他模型
* Aggregate中的模型可以引用其他Aggregate Root, 但只能引用其ID
* 删除操作必须删除Aggregate内的所有模型
* 当对Aggregate做出修改时, Aggregate的Invariant必须都满足, 且存储时必须全部存储, 而不能只存储单个模型

写入整个Aggregate时, 可能导致Aggregate相关的所有table被锁住, 因此可能会影响性能, 但大多数情况下, 写入的正确性比性能优先级更高. 为减少性能的损失, 需要适当地减少Aggregate的大小. 对于读取来说, 有时不需要将Aggregate中的所有模型从数据库中取出, 可借助CQRS模型来对读取做优化.


## 4. How to Find Aggregate
Aggregate的尺寸有一个矛盾之处: Aggregate越大, 复杂度越低, 性能越查; Aggregate越小, 复杂度越高, 性能越好. 所以设计的第一步, 先规划一个大的Aggregate, 以商店为例, 最大的Aggregate就是Shop本身, 但如果将所有业务都放入Shop里, 会发生很多不方便之处, 例如, 当修改Shop里的商品信息时, 必须锁住整个Aggregate, 甚至无法创建新的订单. 
有一个大的Aggregate后, 就对其进行拆分. Aggregate拆分的越小, 系统的性能和拓展性越强, 复杂度也会随之提升. 绝大多数情况下, 若Invariant的约束并不严格, 则可将Aggregate内除Aggregate Root外的Entity数量减少, 最好只保留Value Object. 这里需注意被两个使用者同时修改某个Aggregate的情况. 以商店为例, 其中包含多个Aggregate: Product, Member, Seller. 若将Order放入Member中, 当Member修改Order时, Seller正好也在处理Order, 可能导致Seller的处理失败, 因此需要将Order从Member分离出来, Order中带有MemberID即可.


## 5. Eventual Consistency
Invariant所指的一致性是**transactional consistency**(事务一致性, 所有状态修改同时保存), 而不是**eventual consistency**(最终一致性, 所有状态修改会保存, 但并不是立刻执行), 因此Aggregate Root会将整个Aggregate存储repository, Aggregate的边界也是transaction的边界; 但若某个transaction涉及的Aggregate不止一个, 存在以下两种解决方法:
* 将多个Aggregate打包成一个, 由此保证transactional consistency, 代价是执行效率降低
* 使用eventual consistency, 保证各个Aggregate最终都能正确地修改状态, 代价是各个Aggregate存入repository的时间之间有一定延迟

上述两个方法没有优劣之分, 只取决于transaction的业务属性. 若transaction无法接受时延, 则采用第一种方法; 反之则采用第二种. Aggregate中实现eventual consistency的最常见方式是Domain Event, 接收到状态改变的Aggregate发出Domain Event, 订阅该Aggregate Event的Aggregate会自动处理:
```typescript
// domain/model/Order.ts
class Order {
  close() {
    // ...
    this.setStatus('CLOSED');
    // publish event
    this.events.push(new OrderClosed(this.id, this.buyerId));
  }
}

class OrderClosed implements DomainEvent {
  public orderId: string;
  public buyerId: string;
  public occuredAt: Date;
  constructor(orderId, buyerId) {
    this.orderId = orderId;
    this.buyerId = buyerId;
    this.occuredAt = new Date();
  }
}

const events = require('events');

class CloseOrder {
  private orderRepo: OrderRepository;
  private memberRepo: MemberRepository;
  private eventEmitter: events.EventEmitter;
  constructor(orderRepo: OrderRepository, memberRepo: MemberRepository) {
    this.orderRepo = orderRepo;
    this.memberRepo = memberRepo;
    this.eventEmitter = new events.EventEmitter();
  }

  async execute(input: { orderId: string }) {
    this.eventEmitter.on(
      'OrderClosed',
      async (orderClosed: OrderClosed): void => {
        // increase credit
        const member: Member = await this.memberRepo.ofId(orderClosed.buyerId);
        member.increaseCreditByOrderClosed();
        await this.memberRepo.save(member);
        // another transaction end
      }
    );

    // transaction start
    const order: Order = await this.orderRepo.ofId(input.orderId);
    order.close(); // statu -> 'CLOSED'
    await this.orderRepo.save(order);
    // transaction end

    // send all events
    order.events.forEach(event => this.eventEmitter.emit('OrderClosed', event));
    this.eventEmitter.removeAllListeners();

    return;
  }
}
```
