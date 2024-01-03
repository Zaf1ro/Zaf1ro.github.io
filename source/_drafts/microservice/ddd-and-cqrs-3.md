---
title: DDD and CQRS Pattern (3)
tags:
  - Microservices
category:
  - Microservices
abbrlink: cd1b
date: 2021-02-14 20:28:33
keywords:
description:
---

## 1. Domain model structure in a custom .NET Standard Library
基于DDD model的应用的文件结构如下图所示:
![Domain model structure for the ordering microservice in eShopOnContainers](/images/DDD/3-1.png)

不同的文件夹结构能更清晰地表达应用程序的设计选择. Ordering domain model中有两个aggregate, 一个是order aggregate, 一个是buyer aggregate, 每个aggregate由一组domain entity和value object组成. 当然, aggregate也可以由单个domain entity(aggregate root或root entity)组成.
此外, domain model layer还包含repository contract(interface), 作为domain model的基础结构要求. 换而言之, 这些interface表示infrastructure layer必须实现的repository和method, repository的实现必须放在domain model layer之外, infrastructure layer之中, 这样domain model layer就不会受到基础结构技术中的API或类"污染".
SeedWork文件夹中包含一些base class, 用于domain entity和value object, 可减少代码冗余.


## 2. Structure aggregates in a custom .NET Standard library
一个aggregate表示一组domain object组合, 这些domain object集合在一起用于匹配事务一致性. 这些对象可能是entity实例(其中一个为aggregate root或root entity)和一些value object. **事务一致性**意味着, 保证aggregate在业务操作结束时保持一致且最新状态. 例如: ordering microservice domain model的order aggregate组成如下:
![The order aggregate in Visual Studio solution](/images/DDD/3-2.png)


## 3. Implement domain entities as POCO classes
通过创造POCO class来实现domain entity, 从而实现domain model. 举个例子, Order class被定义为一个entity和aggregate root. 由于Order class继承自Entity基类, 因此可以重用与Entity相关的通用代码. 这些base class和interface定义在domain modal project中, 而不是infrastructure layer或ORM中的代码.
```cs
// COMPATIBLE WITH ENTITY FRAMEWORK CORE 5.0
// Entity is a custom base class with the ID
public class Order : Entity, IAggregateRoot
{
    private DateTime _orderDate;
    public Address Address { get; private set; }
    private int? _buyerId;

    public OrderStatus OrderStatus { get; private set; }
    private int _orderStatusId;

    private string _description;
    private int? _paymentMethodId;

    private readonly List<OrderItem> _orderItems;
    public IReadOnlyCollection<OrderItem> OrderItems => _orderItems;

    public Order(string userId, Address address, int cardTypeId, string cardNumber, 
                 string cardSecurityNumber, string cardHolderName, DateTime cardExpiration, 
                 int? buyerId = null, int? paymentMethodId = null)
    {
        _orderItems = new List<OrderItem>();
        _buyerId = buyerId;
        _paymentMethodId = paymentMethodId;
        _orderStatusId = OrderStatus.Submitted.Id;
        _orderDate = DateTime.UtcNow;
        Address = address;
        // ...Additional code ...
    }

    public void AddOrderItem(int productId, string productName, decimal unitPrice, 
                             decimal discount, string pictureUrl, int units = 1)
    {
        //...
        // Domain rules/logic for adding the OrderItem to the order
        // ...
        var orderItem = new OrderItem(productId, productName, unitPrice, discount, pictureUrl, units);
        _orderItems.Add(orderItem);
    }
    // ...
    // Additional methods with domain rules/logic related to the Order aggregate
    // ...
}
```
作为一个POCO class实现的domain model, 它并不依赖于Entity Framework Core或其他基础结构框架. IAggregateRoot作为一个interface, 其实现为空, 可称为**marker interface**, 仅用于标示该entity class为aggregate root. Marker interface有时被认作是**反模式**, 然而它也是一个对class进行标记的方式, 尤其是该interface可能不断演变时. 属性可以是另一种标记方式, 但将base class(Entity)放在IAggregate interface旁边可能比类中防止一个Aggregate属性更加显眼.
Aggregate root意味着: aggregate entity中的大多数有关一致性和业务逻辑相关的代码, 都被放入Order aggregate root class的函数中. 开发者不能单独或直接创建或更新OrderItems对象, AggregateRoot class应该控制一切child entity中对于一致性的更新操作.


## 4. Encapsulate data in the Domain Entities
Entity model中的一个常见问题是, 它们会将collection navigation properties作为可公开访问的list类型, 这使得任何开发者都可以操作这些集合类型, 并可能会绕过与集合相关的重要业务规则, 从而使对象处于无效状态. 若要解决该问题, 可向相关集合公开只读访问权限, 并显式提供一些函数让客户端操作. 
前面的代码中, 很多属性要么只读, 要么私有, 只能由类方法进行更新, 因此任何更新在类方法中, 其中包含指定业务领域的不变量和逻辑. 使用DDD pattern时, 不能从application layer class或command handler method中执行以下命令:
```cs
// WRONG ACCORDING TO DDD PATTERNS – CODE AT THE APPLICATION LAYER OR
// COMMAND HANDLERS
// Code in command handler methods or Web API controllers
//... (WRONG) Some code with business logic out of the domain classes ...
OrderItem myNewOrderItem = new OrderItem(orderId, productId, productName,
    pictureUrl, unitPrice, discount, units);

//... (WRONG) Accessing the OrderItems collection directly from the application layer // or command handlers
myOrder.OrderItems.Add(myNewOrderItem);
//...
```
Add方法作为一种数据添加操作, 可以直接访问OrderItems集合, 因此child entity中的大部分域逻辑, 规则和验证都会分布到application layer. 如果绕过aggregate root, 则aggregate root无法保证其不变量, 有效性或一致性, 最终产生**spaghetti code**(面条式代码)或**transactional script code**(事务脚本代码).
若要遵循DDD pattern, entity不能在entity属性中拥有public setter, entity中的改变需由显式方法驱动, 这些方法使用显式通用语言来描述它们正在entity中的执行的更改. Entity中的集合(如order items)应为只读属性, 只能从aggregate root中的类方法或child entity的方法中更新它.
从Order aggregate root的代码可以看出, 所有setter都应为私有的, 或者至少从外部只读的. 任何对于entity或child entity中数据的操作都只能由entity class中的方法完成. 这能以面向对象的可控方式来保持一致性, 而不是通过transactional script code. 以下代码为正确地将OrderItem对象添加到Order aggregate的一种方式:
```cs
// RIGHT ACCORDING TO DDD--CODE AT THE APPLICATION LAYER OR COMMAND HANDLERS
// The code in command handlers or WebAPI controllers, related only to application stuff
// There is NO code here related to OrderItem object's business logic
myOrder.AddOrderItem(productId, productName, pictureUrl, unitPrice, discount, units);
// The code related to OrderItem params validations or domain rules should
// be WITHIN the AddOrderItem method.
// ...
```
上述代码中, OrderItem对象创建相关的大部分验证或逻辑都放在Order aggregate root的AddOrderItem方法中, 特别是与aggregate中其他元素相关的验证和逻辑. 例如, 当多次调用AddOrderItem添加相同产品项时, 在该方法内可以检查产品项, 并将相同的产品项合并到具有多个单元的单个OrderItem对象中. 此外, 如果折扣金额不同但产品ID相同, 则可以使用较高的折扣, 此原则适用于OrderItem对象的任何域逻辑.
此外, 创建新的OrderItem操作也由Order aggregate root中的AddOrderItem方法控制和执行, 因此, 与该操作相关的大部分逻辑或验证都位于aggregate root的单个位置, 这也是aggregate root pattern的最终目的.
在DDD中, 如果只通过entity中的方法来更新entity, 以便控制所有不变量和数据一致性, 则属性只应定义get取值函数. 这些属性受私有字段限制, 只能从类中访问私有成员.


## 5. Map properties with only get accessors to the fields in the database table
将属性映射到数据库的table column并不是domain的责任, 而是infrastructure layer的责任. EF Core 1.1或更高版本有关于如何为entity建模的新功能. 使用EF Core 1.0或更高版本时, 需在DbContext中将定义为仅有getter的属性映射到数据库table column, 此操作通过PropertyBuilder类的HasField方法实现.


## 6. Map fields without properties
通过借助EF Core 1.1或更高版本中的功能将column映射到字段, 也可以不使用属性. 常见用例是那些无需从外部访问的, 表示内部状态的私有字段. 例如: OrderAggregate代码示例中有几个私有字段, 比如**_paymentMethodId**字段, 该字段没有setter或getter, 也没有相关属性. 该字段被用于order的事务逻辑和order方法中使用, 但也需要存储到数据库中. 因此EF Core (从v1.1版本起)提供了一种方法, 将无属性相关的字段映射到数据库的column中.
