---
title: DDD and CQRS Pattern (4)
tags:
  - Microservices
category:
  - Microservices
abbrlink: fd19
date: 2021-02-15 14:19:33
keywords:
description:
---

## 1. Seedwork (reusable base classes and interfaces for your domain model)
SeekWork文件夹中包含一些自定义的base class, 用作domain entity和value obejct的基类, 从而避免每个domain entity class的冗余代码. 包含这些class的文件夹称为**SeedWork**而不是Framework, 因为该文件夹仅包含可重用类的一个小子集, 而不能视为一个框架, 也可命名为Common, SharedKernel等其他名称.
![A sample set of domain model "seedwork" base classes and interfaces](/images/DDD/4-1.png)

SeekWork可存在于任何layer或repository中. 但如果类和接口足够大, 可以考虑创建一个单独的类库.

## 2. The custom Entity base class
以下是Entity base class的示范代码, 其中可放置所有domain entity共享的代码, 例如entity ID, equality operator, domain event list.
```cs
// COMPATIBLE WITH ENTITY FRAMEWORK CORE (1.1 and later)
public abstract class Entity
{
    int? _requestedHashCode;
    int _Id;
    private List<INotification> _domainEvents;
    public virtual int Id
    {
        get
        {
            return _Id;
        }
        protected set
        {
            _Id = value;
        }
    }

    public List<INotification> DomainEvents => _domainEvents;
    public void AddDomainEvent(INotification eventItem)
    {
        _domainEvents = _domainEvents ?? new List<INotification>();
        _domainEvents.Add(eventItem);
    }
    public void RemoveDomainEvent(INotification eventItem)
    {
        if (_domainEvents is null) return;
        _domainEvents.Remove(eventItem);
    }

    public bool IsTransient()
    {
        return this.Id == default(Int32);
    }

    public override bool Equals(object obj)
    {
        if (obj == null || !(obj is Entity))
            return false;
        if (Object.ReferenceEquals(this, obj))
            return true;
        if (this.GetType() != obj.GetType())
            return false;
        Entity item = (Entity)obj;
        if (item.IsTransient() || this.IsTransient())
            return false;
        else
            return item.Id == this.Id;
    }

    public override int GetHashCode()
    {
        if (!IsTransient())
        {
            if (!_requestedHashCode.HasValue)
                _requestedHashCode = this.Id.GetHashCode() ^ 31;
            // XOR for random distribution. See:
            // https://docs.microsoft.com/archive/blogs/ericlippert/guidelines-and-rules-for-gethashcode
            return _requestedHashCode.Value;
        }
        else
            return base.GetHashCode();
    }
    public static bool operator ==(Entity left, Entity right)
    {
        if (Object.Equals(left, null))
            return (Object.Equals(right, null));
        else
            return left.Equals(right);
    }
    public static bool operator !=(Entity left, Entity right)
    {
        return !(left == right);
    }
}
```

## 3. Repository contracts (interfaces) in the domain model layer
Repository contract作为.NET接口, 表示repository的协议要求, 用于所有aggregate.
Repository相关的EF Core, 基础结构依赖和代码(Linq, SQL等)不能在domain model中实现, Repository仅实现domain model中定义的接口. 这种做法(domain model layer中放置repository interface)是一种Separated Interface pattern(分隔接口模式), 使用**Separated Interface**在一个package中定义interface, 而在另一个package中实现, 这样需要依赖interface的client完全不需要了解interface的实现.
通过遵循**Separated Interface pattern**, application layer对在domain model定义的要求产生依赖, 而不会对infrastructure layer产生直接依赖. 此外, 可通过在infrastructure layter中使用repository, 从而实现Dependency Injection(依赖注入)来隔离实现.
举个例子, 以下是IOrderRepository interface和OrderRepository class, 其中包含infrastructure layer需要实现的操作. 在当前应用的实现中, 代码只需将订单添加或更新到数据库, 因为查询遵循简化版的CQRS方式拆分.
```cs
// Defined at IOrderRepository.cs
public interface IOrderRepository : IRepository<Order>
{
    Order Add(Order order);

    void Update(Order order);

    Task<Order> GetAsync(int orderId);
}

// Defined at IRepository.cs (Part of the Domain Seedwork)
public interface IRepository<T> where T : IAggregateRoot
{
    IUnitOfWork UnitOfWork { get; }
}
```

