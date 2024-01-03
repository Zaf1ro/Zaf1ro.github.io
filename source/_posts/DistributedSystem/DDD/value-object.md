---
title: Value Object
abbrlink: bc4
date: 2021-04-26 14:56:24
tags:
  - Microservices
category:
  - Microservices
keywords:
description:
---

## 1. Definition
当开发者学习完Entity后, 很容易将所有物品都当做Entity, 这会极大地增加开发难度和系统复杂度; 实际上, 开发者更需要多利用Value Object.
Value Object与Entity正相反, 其没有一个Identity进行标示, 只包含一个或多个属性. 属性的类型可以是不同的, 例如: 数字, 日期, 字符, 或其他value object. 以商品价格为例, 一个商品的价格可用value object来表示, 其中包含两个属性: 币值和币种. Value Object的属性用于描述某个事物的特征, 这也引出了Value Object的几大特征.

### 1.1 Descriptive(描述性)
一栋房子在系统中应作为一个Entity, 因为房子是真实存在的, 且拥有Identity(如房屋地址, 房产信息); 但房屋的房龄, 高度, 颜色, 这些都是描述一栋房屋的属性, 为这些属性设置唯一ID没有意义.

### 1.2 Immutability(不变性)
当一个Value Object被创建后, 则不能再被修改. 虽然不能直接修改Value Object中的属性, 但可以替换整个Value Object. 以房屋为例, 一栋房子可作为Entity, 其房屋颜色是一个Value Object. 假设当前房子的颜色是蓝色, 若我们将其变成红色, 则替换之前的Value Object.

### 1.3 Conceptual Whole(概念整体)
当我们描述事物的某个属性时, 需要完整地描述. 举个例子, 当我们描述商品的价格时, **价格**这个属性至少包含两个属性: 币值和币种. 若开发者将**价格**直接放入**商品**的entity中, 则代码如下:
```typescript
class Product {
  name: string;
  amount: number;
  currency: string;
}
```
当业务需要修改商品价格时, 开发者需明确知道哪些属性应被修改, 这就很难保证业务的正确性. 因此需要将**商品**与**价格**分离, 如下:
```typescript
class Product {
  name: string;
  price: Price;
}

class Price {
  amount: number;
  currency: string;
}
```

### 1.4 Replaceable(可替换性)
为了兼顾**不变性**和**概念整体**, 当Value Object需要被更改时, 需要重新赋值. 例如, 当我们需要将商品价格从100美金换为200美金时, 代码如下:
```typescript
class Product {
  name: string;
  money: Money;

  constructor(name, money) {
    this.name = name;
    this.money = money;
  }

  changePrice(money: Money): void {
    this.money = money;
  }
}

const p = new Product('A', new Money(100, 'USD'));
p.changePrice(new Money(200, 'USD'));
```

### 1.5 Equality(相等性)
由于Value Object没有Identity, 因此只要两个Value Object中的属性全相等, 则Value Object相等. 例如: 蓝色的房屋和蓝色的气球所表示的物体并不相同, 但两者的**蓝色**描述的是同一特征. 由于该特性和不变性, 开发者可将Entity ID设计为Value Object.


## 2. Implement a Value Object
以下是Value Object的base class:
```typescript
interface LiteralObject {
  [index: string]: unknown;
}

abstract class ValueObject<Props extends {}> {
  // Readonly
  props: Readonly<Props>;

  constructor(props: Props) {
    this.props = Object.freeze(props);
  }

  /**
   * Check equality by shallow equals of properties.
   * It can be override.
   */
  equals(obj?: ValueObject<Props>): boolean {
    if (obj === null || obj === undefined) {
      return false;
    }
    if (obj.props === undefined) {
      return false;
    }
    const shallowObjectEqual = (
      props1: LiteralObject,
      props2: LiteralObject
    ) => {
      const keys1 = Object.keys(props2);
      const keys2 = Object.keys(props1);

      if (keys1.length !== keys2.length) {
        return false;
      }
      return keys1.every(
        key => props2.hasOwnProperty(key) && props2[key] === props1[key]
      );
    };
    return shallowObjectEqual(this.props, obj.props);
  }
}
```


## 3. Implement Entity ID by Value Object
```typescript
// EntityId
import { ValueObject } from './ValueObject';
interface EntityIdProps<Value> {
  value: Value;
  occuredDate: Date;
}
export abstract class EntityId<Value> extends ValueObject<EntityIdProps<Value>> {
  constructor(value: Value) {
    super({ value, occuredDate: new Date() });
  }

  get occuredDate(): Date {
    return this.props.occuredDate;
  }

  get value(): Value {
    return this.props.value;
  }

  toString(): string {
    const constructorName = this.constructor.name;
    return `${constructorName}(${String(this.props.value)})-${this.occuredDate.toISOString()}`;
  }

  toValue(): Value {
    return this.props.value;
  }

  equals(entityId: EntityId<Value>): boolean {
    if (entityId === null || entityId === undefined) {
      return false;
    }
    if (!(entityId instanceof this.constructor)) {
      return false;
    }
    return entityId.value === this.value;
  }
}

// Back to Entity
abstract class Entity<Id extends EntityId<unknown>, Props> {
  // ...
}
```


## 4. Persistence of Value Object
首先需要澄清一个概念: domain layer的物品和repository layer的物品是不同的. 开发者偏向于直接将repository layer中的数据拿出来直接当做domain layer的物品. 当设计Entity或Value Object时, 应根据业务逻辑来设计, 而不是根据repository layer.
Entity在repository中有一个位置放置ID, 但Value Object的repository不一定没有ID, 这需要考虑repository的设计.


## 5. How to distinguish between Value Object and Entity
在进行DDD设计时, 开发者应更多地使用Value Object, 而不是Entity, 并不是因为Entity有一个Identity, 而是因为Value Object的生存周期与domain无关. 有时, 同一个物品在不同的Bounded Context中会被分别作为Entity和Value Object. 
举个例子, 现在有两个Bounded Context, 一个是权限管理系统(Identity Access Management, IAM), 另一个是购物系统(Purchasing). 当用户下单时, 会先从IAM获得用户资料与权限, 然后交给Purchasing去生成订单. 对于IAM来说, 用户资料会以Entity的方式存储, 以便随时更新; 而对于Purchasing来说, 用户资料应作为Value Object, 因为Purchasing系统并需要更新任何用户资料或权限. 
Entity:
![Entity](/images/microservice/value-object-1.jpeg)

Value Object:
![Value Object](/images/microservice/value-object-2.jpeg)
