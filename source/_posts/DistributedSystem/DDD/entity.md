---
title: Entity
abbrlink: 1f4
date: 2021-04-22 10:56:30
tags:
  - Microservices
category:
  - Microservices
keywords:
description:
---

## 1. Definition
当与domain experter交流需求时, 总会出现一些概念或实体, 且需要有标志来辨别其唯一性, 如顾客, 订单, 商品. 上述物品不能根据他们的属性所区分(如: 年龄, 金额, 类别), 只能由一个专属的身份标识(Identity)来辨识.
Identity就是Entity的最大特征, entity的属性值可以相同或不同, 但每个entity都必须有唯一的identity. 根据Eric Evans对Entity的描述: Entity是一个不由属性所定义的物品, 而是由**连续性**和**唯一性**所定义的线程, 其跨越系统的整个生命周期, 并可延展到系统之外. 举个例子, 银行账户作为一个entity, 银行系统要追踪其各种状态(余额, 交易记录等), 因此需要为每个账户分配一个ID, 否则不同的账户会混淆.


## 2. Features
以下是Entity的特征:
* 拥有唯一的ID
* 当两个Entity拥有相同的ID时, 无论其状态如何, 都表示同一个物品
* 除了ID外, Entity的其他状态都是mutable(可变的)
* Entity通常由很长的生命周期, 甚至不会被删除
* 一般来说, Entity会有自己的一套CURD操作, 以应对状态的改变

系统中Entity的种类越多, 系统的复杂度越高, 因此需尽量减少Entity的使用. 举个例子, 当设计一个场馆的售票系统时, 场馆的**座位**可以作为entity, Entity的ID可用其位置(第几排第几列)作为唯一标示, 这样用户可购买对号座; 但如果场馆的座位并不需要预定, 而是用户先进先得, 那就不需要将座位当做entity, 只需记录座位的数量.


## 3. Example
以下是Entity的abstract class(written in TypeScript):
```typescript
abstract class Entity<Id, Props> {
  readonly id: Id;
  protected props: Props;

  protected constructor(id: Id, props: Props) {
    this.id = id;
    this.props = props;
  }

  public abstract equals(obj?: Entity<Id, Props>): boolean;
}
```
上述代码中, **equals**函数用于判断两个entity是否表示同一物品.


## 4. Identity
Entity的Identity有多种产生方式:
* 用户输入(User Input): 当用户输入Email地址, 昵称, 或驾照号码, 可使用该信息作为Entity的Identity. 但问题在于这些信息规范不一, 且存在重复的可能性, 所以大多数情况下, 只把这些数据用于搜索或分类, 而不作为Entity的Identity.
* 持久性框架(persistence framework): 这是最常见生产Identity的方式, 例如: SQL中使用**AUTO_INCREMENT**让ID自动递增, 或让数据库生成一个唯一ID. 这种做法的好处是: 减少程序的复杂性, 将工作交由persistence layer处理; 但缺点是, 生成的ID不利于阅读, 且需要考虑生成ID时是否需要将entity持久化.
* 程序生成(Program): 这种方法可以更容易地掌握ID的生成时机, 也更易于开发者阅读. 例如, 一笔订单可以用**order-20210426-abcdefgh-1234**作为ID.
* Bounded Context: 由其他Bounded Context提供ID, 这种方法不仅要考虑本端的Entity, 还需要考虑外部Bounded Context的更改情况. 


## 5. Design an Entity
以下是设计一个Entity的步骤:
1. 划分出关键属性, 将一些用于搜索或分类的属性留在Entity内部, 其他属性放入Value Object中.
2. 生成Entity的Identity
3. 找到关键行为与对应的业务规则, 按照Ubiquitous Language

例如, 我们有一个User class, 其需要两个属性: 姓名和地址, 且这两个属性都可以被更改, 但修改姓名时有个前途: 该User必须处于一个有效状态, 而不是已注销状态, 且姓名不能少于两个character.
```typescript
interface AddressProps {
  city: string;
  county: string;
  street: string;
  detail: string;
}
class Address extends ValueObject<AddressProps> {}

interface UserProps {
  name: string;
  active: boolean;
  address: Address;
}

class User extends Entity<string, UserProps> {
  changeName(name: string): void {
    // check the length of username
    if (name.length < '2') {
      // error handling
    } else {
      this.props.name = name;
    }
  }

  changeAddress(address: Address): void {
    this.address = this.address.update(address);
  }

  static createUser(parmas: {
    id: string;
    name: string;
    address: Address;
  }): [string, User] {
    // check the length of username
    if (name.length < '2') {
      return ['Name length should be less than 2'];
    }

    return [
      undefined,
      new User(params.id, {
        name: params.name,
        active: true,
        address: params.address
      })
    ];
  }

  public equals(obj?: Entity<string, UserProps>): boolean {
    // ...
  }
}
```
