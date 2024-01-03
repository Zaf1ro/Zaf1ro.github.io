---
title: DDD and CQRS Pattern (1)
tags:
  - Microservices
category:
  - Microservices
abbrlink: b145
date: 2021-02-10 18:42:58
keywords:
description:
---

## 1. Overview
DDD(Domain Driven Design)和CQRS(Command Query Responsibility Segregation)可用于降低microservices中业务逻辑的复杂度.
![External microservice architecture versus internal architecture patterns for each microservice](/images/DDD/1-1.png)

## 2. CQRS
CQRS是一种将数据读取和写入分离的pattern(模式), 基本思想是将系统操作划分为两个类别:
1. Query(查询): 返回结果, 不改变系统状态, 且没有任何副作用
2. Command(命令): 改变系统状态

CQS是一个简单的概念: 每个系统的操作要么返回状态, 要么修改状态, 不会两者兼具. CQRS基于CQS原则, 只不过更为详细: CQRS可以当做是基于command和query的pattern, 并提供了异步信息; CQRS还有一些更高级的方案, 比如Query和Command操作的数据库可以是不同数据库(物理层面或数据库类型层面); 更先进的CQRS会为command实现ES(Event-Sourcing, 数据源), 可以让event保存在domain modal中, 而不是状态中. 目前我们只需要了解CQRS的最基本方法, 也就是command与query分离.
CQRS的实现很简单: 把query分为一层, 把command分为另外一层, 每层都有自己的data model(不一定为不同的数据库). Query和command可以在同一个microservice中, 也可以在不同的microservices或进程中, 彼此不会互相影响, 以此做到横向扩展和优化.
CQRS表示有系统中有两个对象用于读/写操作, 以订单系统为例, 以下是一个简化版遵循CQRS的microservices: 
![Simplified CQRS- and DDD-based microservice](/images/DDD/1-2.png)

上图可看到, CQRS pattern将ViewModels和query从command和Domain Model中分离出来, 这种方法使得query跳脱出DDD pattern的限制和约束, 而DDD pattern只对事务和更新有效. CQRS pattern的本质是: 查询是idempotent(幂等的, 任意多次执行所产生的影响均与一次执行的影响相同), 无论query操作执行多少次, 都不会对系统状态产生任何改变. 换句话说, query没有任何副作用. 因此, query和command可以使用不同的data model, 即使该例中query和command使用相同数据库.
对于command来说, 由于涉及到系统状态的改变, 以及不断变化的业务逻辑, command会变得十分复杂, 使用时也应小心谨慎. 因而DDD应运而生, 可以降低command的复杂度, 并实现更好的model system.
其中一种实现DDD的方式为Aggregate pattern, 根据object在domain中的关系, 将多个object作为单个unit来对待. 但对于query来说, 将多个object结合为一个aggregate只会增加复杂度. 因此只在transactional/updates领域(由command引发的操作)使用DDD pattern; 对于query, 有很多成熟的ORM可供选择: EF Core, AutoMapper projections, stored procedures, views, materialized views或micro ORM.

## 3. CQRS和DDD并不是顶层架构
CQRS和DDD并不是一种架构类型(architecture), 而是一种架构模式(pattern), Microservices, SOA和EDA(event-driven architecture)才是架构. Architecture描述的是所有component组成的系统, 而pattern描述的是系统中的一部分内容. 不同的BCs(Bounded Contexts)使用不同的pattern, 分别具有不同的职能, 并导向不同的解决方案. CQRS和DDD并不适用于所有地方, 如果mircoservices足够简单, 也可以使用CURD或其他方法实现.

## 4. reads/queries in a CQRS microservice
read/query并不采用DDD pattern, 因为两者的需求十分不同. Command/write必须遵循业务逻辑, 但read/query则不需要.
![The simplest approach for queries in a CQRS microservice](/images/DDD/1-3.png)

上图中, API interface通过ORM从数据库中获取数据, 并根据UI app的需求返回一个ViewModal. Query definition查询数据库, 并根据查询结果返回一个ViewModal. 由于query是**幂等**的, 因此无论query进行多少次, 都不会影响数据. SQL语句需要静态定义, 但任何动态的ViewModel都不需要静态定义. 由于query部分很简单, 代码可在同一web项目中实现. 如下图:
![Queries in the Ordering microservice in eShopOnContainers](/images/DDD/1-4.png)

## 5. Use ViewModels specifically made for client apps, independent from domain model constraints
由于query是根据client application的需求来获取数据, 因此可以为client单独定制返回的数据类型. 这种model或DTO(Data transfer object)称为ViewModel. ViewModel可以是数据库中多个entity或table联结的结果, 也可以横跨domain model中的多个aggregate. 由于query独立于domain model, 因此会忽略aggregates boundaries和constraint. ViewModel既可以是静态定义的class, 也可以是动态生成的.

## 6. Use Dapper as a micro ORM to perform queries
micro ORM, Entity Framework Core和plain ADO.NET都可以用于实现query, 本文将用Dapper作为ordering microservice的micro ORM. Dapper对于执行SQL语句有很好的性能, 且较为轻量级. 

## 7. Dynamic versus static ViewModels
当server返回ViewModel给client application时, ViewModel可被视为DTO, 但由于ViewModel拥有client app所需要的数据, 因此ViewModel不同于entity model中的domain entity. 多数情况下, 程序员需要根据client app的需求, 将多个domain entities中的数据聚合在一起. ViewModel可以是被明确定义(如data holder class), 也可以是动态ViewModel.

## 8. ViewModel as dynamic type
下面是一个动态生成ViewModel的例子:
```cs
using Dapper;
using Microsoft.Extensions.Configuration;
using System.Data.SqlClient;
using System.Threading.Tasks;
using System.Dynamic;
using System.Collections.Generic;

public class OrderQueries : IOrderQueries
{
    public async Task<IEnumerable<dynamic>> GetOrdersAsync()
    {
        using (var connection = new SqlConnection(_connectionString))
        {
            connection.Open();
            return await connection.QueryAsync<dynamic>(
                @"SELECT o.[Id] as ordernumber,
                         o.[OrderDate] as [date],
                         os.[Name] as [status],
                  SUM(oi.units*oi.unitprice) as total
                  FROM [ordering].[Orders] o
                  LEFT JOIN[ordering].[orderitems] oi ON o.Id = oi.orderid
                  LEFT JOIN[ordering].[orderstatus] os ON o.OrderStatusId = os.Id
                  GROUP BY o.[Id], o.[OrderDate], os.[Name]");
        }
    }
}
```
根据query的参数类型, dynamic类型会返回相应类型的ViewModel. 这意味着, query决定了返回的属性包含哪些, 调用query的程序员可以动态地添加或删除某个需要的column. 
* 优点: 减少了修改static ViewModel class的次数, 编码变得更加灵活, 直观
* 缺点: dynamic类型会让后续维护和兼容性造成不利影响

## 9. ViewModel as predefined DTO classes
以下代码中的query返回一个ViewModel DTO class(OrderSummary)
```cs
using Dapper;
using Microsoft.Extensions.Configuration;
using System.Data.SqlClient;
using System.Threading.Tasks;
using System.Dynamic;
using System.Collections.Generic;

public class OrderQueries : IOrderQueries
{
  public async Task<IEnumerable<OrderSummary>> GetOrdersAsync()
    {
        using (var connection = new SqlConnection(_connectionString))
        {
            connection.Open();
            return await connection.QueryAsync<OrderSummary>(
                  @"SELECT o.[Id] as ordernumber,
                  o.[OrderDate] as [date],os.[Name] as [status],
                  SUM(oi.units*oi.unitprice) as total
                  FROM [ordering].[Orders] o
                  LEFT JOIN[ordering].[orderitems] oi ON  o.Id = oi.orderid
                  LEFT JOIN[ordering].[orderstatus] os on o.OrderStatusId = os.Id
                  GROUP BY o.[Id], o.[OrderDate], os.[Name]
                  ORDER BY o.[Id]");
        }
    }
}
```
建议在开发早起使用dynamic type, 因为具有直观性和灵活性; 但一旦开发进入稳定期, 建议重构API, 将ViewModel换为static DTO, 因为这样使用者可以更加清晰地了解DTO的类型.

## 10. Describe response types of Web APIs
开发者使用Web API和microservices时最关心的莫过于其返回的数据类型和错误码.
```cs
namespace Microsoft.eShopOnContainers.Services.Ordering.API.Controllers
{
    [Route("api/v1/[controller]")]
    [Authorize]
    public class OrdersController : Controller
    {
        //Additional code...
        [Route("")]
        [HttpGet]
        [ProducesResponseType(typeof(IEnumerable<OrderSummary>),
            (int)HttpStatusCode.OK)]
        public async Task<IActionResult> GetOrders()
        {
            var userid = _identityService.GetUserIdentity();
            var orders = await _orderQueries
                .GetOrdersFromUserAsync(Guid.Parse(userid));
            return Ok(orders);
        }
    }
}
```
如果没有在Swagger UI中添加文档, 则使用者很难确定返回数据的类型和HTTP code, 因此需要添加**Microsoft.AspNetCore.Mvc.ProducesResponseTypeAttribute**. 由于**ProducesResponseType**不能使用dynamic作为类型, 因此需要使用显式类型, 如: OrderSummary.
```cs
public class OrderSummary
{
    public int ordernumber { get; set; }
    public DateTime date { get; set; }
    public string status { get; set; }
    public double total { get; set; }
}
```
这也是显式类型优于动态类型的其中一个原因: 从长期来说, 一旦使用**ProducesResponseType**, 就必须标注其类型对应的HTTP code. 以下是Swagger UI显式的返回结果:
![Swagger UI showing response types and possible HTTP status codes from a Web API](/images/DDD/1-5.png)
