---
title: Validation Rule
tags:
  - Microservices
category:
  - Microservices
abbrlink: 9d18
date: 2021-02-16 15:30:59
keywords:
description:
---

## 1. Design validations in the domain model layer
在DDD中, validation rule(验证规则)可当做invariant(不变式). 一个aggregate的主要责任是针对aggregate内所有entity, 在状态变化中强制执行invariant.
Domain entity应该始终为有效上的entity, 单个对象的多个invariant应始终为true. 举个例子, order item对象的数量应为正整数. 因此, 强制执行invariant是domain entity的责任(尤其是aggregate root), 且任何无效的entity都不应该存在. Invariant rule只需表达为contract(协议), 即违反时会引发异常或通知. 很多bug都是因对象处于不应处于的状态而触发. 
现在假设我们有一个使用UserProfile的SendUserCreationEmailService, 我们如何说服自己该service中的name不为null呢? 是否需要再次检查? 或放弃检查, 寄希望于其他人检查过了. 当然, 使用TDD(Test Driven Development)时, 我们可以写一个测试, 让name为null来查看是否会触发error. 但一旦反复地写此类测试代码, 我们就会意识到: 如果从根本上不允许name为null, 我们就不需要做这些测试.

## 2. Implement validations in the domain model layer
Validation通常在domain entity的构造函数或更新entity的函数中实现. Validation可以采用某些更高级的pattern, 例如Specification pattern, 还有Notification pattern可用于返回一个error集合, 而不是为每个validation返回exception.

### 2.1 Validate conditions and throw exceptions
以下代码展示了domain entity中一个最简单的validation方式: 直接抛出异常. 
```cs
public void SetAddress(Address address)
{
    _shippingAddress = address?? throw new ArgumentNullException(nameof(address));
}
```
下面代码将使得对象保持在无效状态, 即: 要么对象内部状态不改变, 要么方法内的改变都发生.
```cs
public void SetAddress(string line1, string line2,
    string city, string state, int zip)
{
    _shippingAddress.line1 = line1 ?? throw new ...
    _shippingAddress.line2 = line2;
    _shippingAddress.city = city ?? throw new ...
    _shippingAddress.state = (IsValid(state) ? state : throw new …);
}
```
如果state值无效, 由于line1和city都已经被更改, 该地址将变得无效. 相同的方式也可以作用在entity的构造函数中, 要么entity被正确创建, 要么抛出异常.

### 2.2 Use validation attributes in the model based on data annotations
Data anotation就像Required或MaxLength属性, 都可以用于配置EF Core数据库的字段属性. 但从DDD的角度来说, 最好通过在entity的行为方法中使用异常, 或者通过实现**Specification pattern**和**Notification pattern**来执行validation rule, 从而使domain model保持精简.
也可以在接收输入的ViewModel(application layer中, 而不是domain entity中)中使用data annotation, 以允许在UI层进行model validation. 但这并不能成为domain model不做验证的借口.

### 2.3 Validate entities by implementing the Specification pattern and the Notification pattern
通过将Specification pattern与Notification pattern结合起来, 可以在domain model中实现一种更复杂的validation. 当然也可以只使用其中一种pattern, 例如: 在控制语句中手动验证, 但在返回validation error时使用Notification pattern.

### 2.4 Use deferred validation in the domain
有多种方法可以实现延迟验证. 在**Implementing Domain-Driven Design**一书中有提到.

### 2.5 Two-step validation
也可以在项目中使用多重验证, 在DTO(Data Transfer Object)中使用field-level validation, 在entity中使用domain-level validation. 从而通过返回对象来处理验证错误, 而不是抛出异常. 例如, 将field validation和data annotation一起使用, 其实并没有重复validation. 对于DTO, validation的执行一个在server端(command), 一个在client端(ViewModel).

## 3. Client-side validation
即使数据来源是domain model, 也必须在domain model级别进行验证. Validation可以在domain model level(server端)进行, 也可以在UI(client端).
Client端验证极大地方便了用户, 这样可以节省用户等待往返服务器所需的时间. 从商业角度来说, 即使每次验证只要几分之一秒, 若每天发生上百次验证, 也会耗费大量时间和成本. 简单直接的验证可以提高用户工作效率和投入产出比.
由于view model和domain model是不一样的, 即使view model validation和domain model validation相似, 但目的却是不同的. 考虑到**DRY**(Don't Repeat Yourself原则), 验证代码复用可能导致耦合; 但对于企业级应用, 比起DRY原则, 不要将server端耦合到client端更重要.
即使client端已经有验证, 我们还是需要在server端检验command或输入的DTO, 因为server API可能是某种攻击媒介. 通常来说, 要在两端验证. 从UI的角度来说, 如果我们有一个client application, 最好采取主动防御并防止用户输入无效信息.
因此, client端通常会对ViewModel进行验证, 也可以在发送DTO或command到service前进行验证. Client端的验证实现取决于client的应用类型.

## 4. Validation in SPA Web apps (Angular 2, TypeScript, JavaScript)
与validation有关的概念有以下几条:
* Entity和aggregate应确保一致性, 并始终保持**有效**. Aggregate root保证同一aggregate内多个entity保持一致性.
* 若entity需进入**无效**状态, 可考虑使用不同object model, 例如: 在创建最终domain entity前返回一个临时DTO
* 若需要创建多个相关对象(如aggregate), 且只有完成创建所有对象后才有效, 可考虑使用**Factory pattern**
* 大多数情况下, client端可采用冗余验证
