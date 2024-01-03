---
title: Domain Event
tags:
  - Microservices
category:
  - Microservices
abbrlink: d19
date: 2021-02-17 13:57:40
keywords:
description:
---

## 1. What is a domain event?
Event表示过去已发生的某事物. Domain event表示domain中已发生的某件事, 该事件需要同一domain中的其他部分了解. 通常来说, 被通知的部分需要对event做出一些反应. Domain event的明显优点是将副作用(由event handler触发的行为)显式表示出来. 
例如, 当我们使用Entity Framework并希望其对某些event做出反应时, 我们需要在触发event的地方编写相应代码. 这会增加耦合, 并让后续开发者很难找到各个event handler的位置.
另一方面, 使用domain event可让概念明确, 因为一个**DomainEvent**对应着一个或多个**DomainEventHandler**. 举个例子, 在电商应用中, 当一个order被创建时, 用户变为一个buyer, 这时会生成一个**OrderStartedDomainEvent**并交由**ValidateOrAddBuyerAggregateWhenOrderStartedDomainEventHandler**处理.
简而言之, domain event可根据domain expert提供的通用语言来显式表达domain rule. Domain event还可更好地将关注点分布到同一domain的不同class中. 务必确保, 所有有关domain event的操作要么成功完成, 要么一个都不完成, 就像database transaction.
Domain event类似于message-style event, 但有一点不同: 通过real messageing, message queye, message broker或使用AMQP的service bus, 信息会被异步发送, 并在进程或机器之间传递. 这对于集成多个BC, microservices或应用很有用. 然而对于domain event, domain operation引发的event, 其副作用只能在同个domain发生.
Domain event和其副作用一般同时发生, 通常发生在同一进程或同一domain. Domain event可以是同步或异步的, 但integration event应为异步的.


## 2. Domain events versus integration events
从语义上看, domain event和integration event是一样的: 都是对已发生事件的通知. 然而它们的实现是不同的. Domain event只是推送给domain event dispatcher的信息, 可使用基于IoC container的in-memory mediator来实现.
但integration event的目的是将已提交的事务或更新传递给其他子系统, 无论子系统是microservice, BC, 还是其他应用. 因此, 只有entity被成功保存时, integration event才会发生; 否则整个操作都如同没有发生过一样. Integration event必须基于多个microservice, BC或外部系统间的异步通信. 
因此, event bus interface需要一些基础结构来实现远程服务之间的分布式通信. 它可以基于一个商用service bus, queue, 用于mailbox的共享数据库, 或分布式信息推送系统.


## 3. Domain events as a preferred way to trigger side effects across multiple aggregates within the same domain
当在一个aggregate实例中执行一个command时, 需要在其他一个或多个aggregate中运行其他domain rule, 我们需要设计并实现domain event触发的副作用. 如下图所示, domain event应当把state change这一消息传播给同一domain下的其他多个aggregate.
![Domain events to enforce consistency between multiple aggregates within the same domain](/images/DDD/7-1.png)

上图展示了domain event如何实现aggregate间的一致性. 当用户发起订单时, Order Aggregate将发送一个**OrderStarted** domain event. Buyer Aggregate会处理**OrderStarted** domain event, 并基于identity microservice中的用户信息, 在ordering microservice中创建一个Buyer对象.
或者, 我们可以让aggregate root订阅其child entity触发的event. 举个例子, 当商品价格高于某个金额时, 或当商品数量过多时, OrderItem child entity都会触发一个event, aggregate root接收到这些事件后会进行一个全局计算或聚合.
注意, 基于event的通信并不能在aggregate内直接实现, 我们需要实现domain event handler. Domain model layer只应关注domain logic, 而处理domain event是应用程序所需要关心的问题, 所以domain model layer不应关注handler和副作用持久化行为. 因此, 当某domain event被触发时, 处理event的domain event handler应位于application layer.
Domain event也可用于触发多个application action(应用操作), 并且必须通过一种分离的方式来增加应用操作的数量. 举个例子, 当order开始时, 我们需要发布一个domain event, 把它交给其他aggregate, 或触发一个application action.
关键是domain event发生时, 需要操作的行动数量. 随着domain和application中action和rule的发展, action的复杂度和数量也会随着增加. 若我们把所有action代码放在一起, 那么每次新增一个action, 都需要修改大量工程代码和测试代码.
这样的代码修改不仅会带来新的bug, 还会破坏**SOLID**中的**SRP**(Single Responsibility Principle和**Open/Closed principle**. 但若使用domain event, 可通过隔离职责的方法来解耦:
1. 发送command(例如: CreateOrder)
2. 在command handler中接收command
  1. 执行单个aggregate事务
  2. 可选: 触发domain event以产生副作用(例如: OrderStartedDomainEvent)
3. 处理domain event, 这些domain event会在多个aggregate或application action中执行不定数个副作用. 例如:
  * 验证并创建buyer和支付方式
  * 创建并发送一个相关的integration event到event bus, 并传送给其他microservice或触发外部行为(如: 向buyer发送邮件)
  * 处理其他副作用

![Handling multiple actions per domain](/images/DDD/7-2.png)

上图中, 从domain event开始, 我们可以处理多个action, 有的action与单个domain中与多个aggregate相关; 有的action需要通过integration event和event bus进行跨microservice操作.
在application layer, 同一个domain event可以有多个handler, 一个handler用于处理多个aggregate的一致性问题, 另个handler用于发布integration event, 以便其他microservice对此进行操作. 通常情况下, event handler都会放在application layer, 因为我们需要使用infrastructure object, 例如: repository或application API. Event handler和command handler很相似, 都是application layer的一部分. 一个domain event可以被处理0次或多次, 因为一个event可因不同目的而被不同event handler处理.
让domain event都有不定数量的domain event handler, 这种做法可让开发者任意添加新的domain rule, 且不会对之前的代码有任何影响. 例如, 实现以下business rule只需要添加几个event handler: 当消费者在商店内消费的总金额超过6000块时, 会对每件新订单提供10%的折扣, 并通过邮件通知客户将来订单的折扣.


## 4. Implement domain events
在C#中, domain event可以是一个data-holding structure或class(如DTO), 其中包含domain中与event相关的所有信息.
```cs
public class OrderStartedDomainEvent : INotification
{
    public string UserId { get; }
    public int CardTypeId { get; }
    public string CardNumber { get; }
    public string CardSecurityNumber { get; }
    public string CardHolderName { get; }
    public DateTime CardExpiration { get; }
    public Order Order { get; }

    public OrderStartedDomainEvent(Order order, int cardTypeId, 
        string cardNumber, string cardSecurityNumber, 
        string cardHolderName, DateTime cardExpiration)
    {
        Order = order;
        CardTypeId = cardTypeId;
        CardNumber = cardNumber;
        CardSecurityNumber = cardSecurityNumber;
        CardHolderName = cardHolderName;
        CardExpiration = cardExpiration;
    }
}
```
上面的代码中包含了OrderStarted event所需要的所有信息. 由于event表示过去发生的事件, 因此event的class名应表示为**past-tense verb**(过去时动词), 如OrderStartedDomainEvent或OrderShippedDomainEvent. 也由于event是过去发生的事件, 因此是**不可修改的**, class也不应被修改. 上述代码中所有属性都是**只读的**, 只能在创建对象时设置属性值. 这里需要强调一点, 若domain event被异步处理, 由于需要序列化和反序列化event对象, 因此属性应设置为private set, 而不是read-only. 这并不是ordering microservice的问题, 而是使用MediatR作为domain event pub/sub时的实现问题.


## 5. Raise domain events
有多种方法可以引发domain event, 以便event handler接收并处理. 可以选择使用一个static class来管理并触发event. 例如, 创建一个static class名为DomainEvents, 当需要触发domain event时则调用**DomainEvents.Raise(Event myEvent)**. 
但当domain event class为静态时, event会被立即发送给handler, 这使得test和debug变得更加困难, 因为当event被触发时, 其含有副作用的handler会立刻执行. 当我们测试或debug时, 我们更希望聚焦于当下aggregate class发生了什么, 而不想让event handler立即接手(这样会牵扯到其他aggregate或其他应用逻辑).

### 5.1 The deferred approach to raise and dispatch events
相比于将domain event立即发送给handler, 更好的方式是: 将domain event添加一个collection中, 并在提交事务之前或之后发送这些domain event. 其中很重要的一点是: 我们需要在提交事务前发送domain event, 还是之后. 因为这决定了副作用被包括在同一事务, 还是不同的事务. 如果是不同的事务, 我们需要处理跨多个aggregate的eventual consistency(最终一致性)问题.
以下是一个deferred approach的例子: 首先我们需要将每个entity中的event添加到各自的collection中. 该collection应为entity对象的一部分, 因此我们将其写入到Entity base class中.
```cs
public abstract class Entity
{
    //...
    private List<INotification> _domainEvents;
    public List<INotification> DomainEvents => _domainEvents;

    public void AddDomainEvent(INotification eventItem)
    {
        _domainEvents = _domainEvents ?? new List<INotification>();
        _domainEvents.Add(eventItem);
    }

    public void RemoveDomainEvent(INotification eventItem)
    {
        _domainEvents?.Remove(eventItem);
    }
    //... Additional code
}
```
当需要触发event时, 需调用aggregate root entity中的方法, 并在其中调用AddDomainEvent()将event加入到event collection. 以下是Order aggregate root中的部分代码:
```cs
private void AddOrderStartedDomainEvent(string userId, string userName,   
    int cardTypeId, string cardNumber, string cardSecurityNumber, 
    string cardHolderName, DateTime cardExpiration)
{
    var orderStartedDomainEvent = new OrderStartedDomainEvent(this, userId, userName, cardTypeId, cardNumber, cardSecurityNumber, cardHolderName, cardExpiration);
    this.AddDomainEvent(orderStartedDomainEvent);
}
```
上述代码只是将event添加到list中, event并未被触发, 也并没有handler去处理. 当需要提交该事务到数据库时, 我们想触发这些event. 若使用Entity Framework Core, 则意味着在EF DbContext中调用SaveChanges.
```cs
// EF Core DbContext
public class OrderingContext : DbContext, IUnitOfWork
{
    // ...
    public async Task<bool> SaveEntitiesAsync(CancellationToken cancellationToken = default(CancellationToken))
    {
        // Dispatch Domain Events collection.
        // Choices:
        // A) Right BEFORE committing data (EF SaveChanges) into the DB. 
        // This makes a single transaction including side effects from the domain event handlers 
        // that are using the same DbContext with Scope lifetime
        // B) Right AFTER committing data (EF SaveChanges) into the DB. 
        // This makes multiple transactions. You will need to handle eventual consistency 
        // and compensatory actions in case of failures.
        await _mediator.DispatchDomainEventsAsync(this);

        // After this line runs, all the changes (from the Command Handler and Domain
        // event handlers) performed through the DbContext will be committed
        var result = await base.SaveChangesAsync();
    }
}
```
通过上述代码, 可将entity event发送给对应的event handler. 这样做的结果就是: 将**触发domain event**和**派送给event handler**解耦. 此外, 同步或异步派送event取决于dispatcher的类型. Transactional boundary也很重要. 若transaction可以横跨几个aggregate(如EF Core和relational database), 则一切工作正常; 但若使用NoSQL database(如Azure CosmosDB), 则无法保证一致性, 需做一些额外工作. 


## 6. Single transaction across aggregates versus eventual consistency across aggregates
执行跨aggregate的单个transaction, 还是依赖跨aggregate的最终一致性, 这是一个有争议的问题. 很多DDD的作者认为: 一个transaction等同于一个aggregate, 因此主张跨aggregate的最终一致性. 
在**Domain-Driven Design**一书中写到: 跨aggregate的任何规则都不会始终保持最新状态. 通过事件处理, 批处理或其他更新机制，可以在某些特定时间内解决依赖性. 在**Effective Aggregate Design. Part II: Making Aggregates Work Together**一书中写到: 如果在一个aggregate实例中执行command时, 需要其他一个或多个aggregate上的业务规则, 则需要用到**最终一致性**. DDD model中有一个很实用的方法来保证最终一致性: aggregate方法发布一个domain event, 并及时将event发送给一个或多个异步订阅者.
上述观点基于将transaction细分, 而不是将一个大的transaction分给多个aggregate或entity. 如果基于第二种情况, 在具有高可拓展性的大型应用中, 数据库的锁将变得非常多. 如果想实现一个高拓展性的应用, 那么在多个aggregate中保持instant transactional consistency(立即事务一致性)是没必要的, 这一点有助于我们去接收最终一致性. 业务通常不需要atomic change(原子修改), 若某个操作需要在多个aggregate中实现atomic transaction, 则我们需要思考是否需要合并aggregate, 或重新设计aggregate.
当然, 也有一些开发者和架构师认为应支持跨aggregate执行单个transaction, 但前提是command中的副作用需要其他aggregate参与. 通常情况下, domain event发生在同一逻辑transaction, 但不一定是引发domain event的同一作用域. 

