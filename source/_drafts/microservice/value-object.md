---
title: Value Object
abbrlink: 5b41
date: 2021-02-15 19:19:53
tags:
  - Microservices
category:
  - Microservices
keywords:
description:
---

## 1. Implement value objects
Identity对于entity是不可缺少的, 但系统中有很多对象和数据并不需要identity, 如value object(值对象). 一个value object可以引用其他entity, 例如, 应用中生成路由来描述如何从一点到另一点的路由, 这个路由应为value object. 它可以是特定路由上point的快照, 但路由并没有identity, 即使路由内部可能指向城市, 街道等entity.
![Address value object within the Order aggregate](/images/DDD/5-1.png)

如上图所示, 一个entity通常包含多个属性. 例如, **Order** entity可以塑造为含有一个identity和多个属性(如: OrderId, OrderDate, OrderItems)的entity. 但address作为一个包含country/region, street, city等复合值, 在domain中是没有identity的, 必须被塑造成value object.

## 2. Important characteristics of value objects
Value object有两个主要特征:
* 没有identity
* 不可变

第一个特征前文已经讨论过, 不可变性是一个重要的要求. Value object的值必须是不可变的, 因此当创造对象时, 必须提供所需的值, 且不允许它们在生存周期内进行更改. 
因其不可变性, value object允许采取某些技巧来提升性能. 当系统中有成千上万个value object实例, 且其中很多都是相同值时, 不可变性使得它们可以被重用. 由于value object中的值是相同的, 且没有identity, 因此它们是可交换的. 这一类差异决定了软件是否跑的够快. 当然, 所有这些取决于应用的环境和部署上下文.

## 3. Value object implementation in C#
就实现而言, 我们可以实现一个value object base class, 它具有value object的重要特性和一些基于属性的对比方法. 以下是ordering microservice中的value object base class:
```cs
public abstract class ValueObject
{
    protected static bool EqualOperator(ValueObject left, ValueObject right)
    {
        if (ReferenceEquals(left, null) ^ ReferenceEquals(right, null))
        {
            return false;
        }
        return ReferenceEquals(left, null) || left.Equals(right);
    }

    protected static bool NotEqualOperator(ValueObject left, ValueObject right)
    {
        return !(EqualOperator(left, right));
    }

    protected abstract IEnumerable<object> GetEqualityComponents();

    public override bool Equals(object obj)
    {
        if (obj == null || obj.GetType() != GetType())
        {
            return false;
        }

        var other = (ValueObject)obj;

        return this.GetEqualityComponents().SequenceEqual(other.GetEqualityComponents());
    }

    public override int GetHashCode()
    {
        return GetEqualityComponents()
            .Select(x => x != null ? x.GetHashCode() : 0)
            .Aggregate((x, y) => x ^ y);
    }
    // Other utility methods
}
```
当实现value object时可使用该base class, 例如下面的Address value object:
```cs
public class Address : ValueObject
{
    public String Street { get; private set; }
    public String City { get; private set; }
    public String State { get; private set; }
    public String Country { get; private set; }
    public String ZipCode { get; private set; }

    public Address() { }

    public Address(string street, string city, string state, string country, string zipcode)
    {
        Street = street;
        City = city;
        State = state;
        Country = country;
        ZipCode = zipcode;
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        // Using a yield return statement to return each element one at a time
        yield return Street;
        yield return City;
        yield return State;
        yield return Country;
        yield return ZipCode;
    }
}
```
可以看到, 该Address并没有identity, 因此Address类中和ValueObject类中都没有ID字段. 在EF Core 2.0之前, EF(Entity Framework)使用的类中是不能没有ID字段的, EF Core 2.0不再要求ID字段, 在value object的实现方面有很大作用.
由于value object是不可变的, 所以应为只读的. 但value object通常会被message queue序列化和反序列化, 且**只读**会让deserializer无法分配值, 因此需将属性设为**private set**.
