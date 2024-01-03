---
title: Why Use DDD
abbrlink: a6fe
date: 2020-12-29 10:54:02
tags:
  - Microservices
category:
  - Microservices
keywords:
description:
---

## 1. What is Architecture
Architecture(架构)的概念来自于土木工程中的"建筑"和"结构", 在软件开发中更多地指代那些代码机构, 设计模式, 规范和组件间的通信方式. 一个好的架构, 应满足以下几个目标:
* 独立于框架: 架构不应该依赖某个外部的库或框架
* 独立于UI: 前端展示随时发生变化, 但是底层架构不应该随之改变
* 独立于底层数据源: 无论今天你用MySQL, MongoDB, 还是文件系统, 架构都不应产生巨大改变
* 独立于外部依赖: 无论外部依赖如何变更, 升级, 业务的核心逻辑不应该随之而大幅变化
* 可测试: 无论外部依赖了什么样的硬件, UI或者服务, 业务的逻辑应该都能够快速被验证正确性


## 2. Transaction Script
假设我们现在要实现一个银行转账功能, 支持跨币种, 基本需求可以拆解成以下几个步骤:
1. 从MySQL中找到转入和转出账户, 选择用MyBatis的mapper实现DAO
2. 从Yahoo(或其他渠道)获得当前汇率信息
3. 确保转出账户上有足够的约, 且未超出每日转账上限
4. 实现转入转出, 扣除手续费, 保存数据库
5. 发送Kafka审计信息, 以便后续审计和对账

代码实现如下:
```java
public class TransferController {
    private TransferService transferService;

    public Result<Boolean> transfer(String targetAccountNumber, BigDecimal amount, HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        return transferService.transfer(userId, targetAccountNumber, amount, "CNY");
    }
}

public class TransferServiceImpl implements TransferService {
    private static final String TOPIC_AUDIT_LOG = "TOPIC_AUDIT_LOG";
    private AccountMapper accountDAO;
    private KafkaTemplate<String, String> kafkaTemplate;
    private YahooForexService yahooForex;

    @Override
    public Result<Boolean> transfer(Long sourceUserId, String targetAccountNumber, BigDecimal targetAmount, String targetCurrency) {
        // 1. 从数据库读取数据，忽略所有校验逻辑如账号是否存在等
        AccountDO sourceAccountDO = accountDAO.selectByUserId(sourceUserId);
        AccountDO targetAccountDO = accountDAO.selectByAccountNumber(targetAccountNumber);

        // 2. 业务参数校验
        if (!targetAccountDO.getCurrency().equals(targetCurrency)) {
            throw new InvalidCurrencyException();
        }

        // 3. 获取外部数据，并且包含一定的业务逻辑
        // exchange rate = 1 source currency = X target currency
        BigDecimal exchangeRate = BigDecimal.ONE;
        if (sourceAccountDO.getCurrency().equals(targetCurrency)) {
            exchangeRate = yahooForex.getExchangeRate(sourceAccountDO.getCurrency(), targetCurrency);
        }
        BigDecimal sourceAmount = targetAmount.divide(exchangeRate, RoundingMode.DOWN);

        // 4. 业务参数校验
        if (sourceAccountDO.getAvailable().compareTo(sourceAmount) < 0) {
            throw new InsufficientFundsException();
        }
        if (sourceAccountDO.getDailyLimit().compareTo(sourceAmount) < 0) {
            throw new DailyLimitExceededException();
        }

        // 5. 计算新值，并且更新字段
        BigDecimal newSource = sourceAccountDO.getAvailable().subtract(sourceAmount);
        BigDecimal newTarget = targetAccountDO.getAvailable().add(targetAmount);
        sourceAccountDO.setAvailable(newSource);
        targetAccountDO.setAvailable(newTarget);

        // 6. 更新到数据库
        accountDAO.update(sourceAccountDO);
        accountDAO.update(targetAccountDO);

        // 7. 发送审计消息
        String message = sourceUserId + "," + targetAccountNumber + "," + targetAmount + "," + targetCurrency;
        kafkaTemplate.send(TOPIC_AUDIT_LOG, message);

        return Result.success(true);
    }
}
```
可以看到, 这段代码包含了多个功能: 参数校验, 数据读取和存储, 业务处理, 调用外部服务, 发送信息. 真实开发中可能会将代码拆分到多个函数中, 但实际效果类似. 这种代码称为**Spaghetti Code**(面条式代码)和**Transaction Script**(事务脚本)和, 这种pattern对于小型应用没有问题, 可以快速实现业务功能; 但对于大型项目来说, 存在诸多问题.


## 3. Maintainability
评判可维护性, 取决于依赖发生变化时, 有多少代码需要随之更改. 需要修改的越少, 则可维护性越强. 上述代码之所以可维护性差, 因为以下几点:
* 数据结构不稳定: AccountDO映射数据库中一个table, 数据库的sharding, table重设计, 或table中字段重命名都会影响该数据结构
* 依赖库升级: 上述代码使用到了MyBatis, 若MyBatis升级迭代, 可能造成某些功能发生改变. 无论是升级MyBatis或更换ORM, 成本都很巨大.
* 第三方服务依赖: 上述代码使用Yahoo作为汇率服务, 外部服务的任何变化都会影响代码的运行, 如签名的更换, 服务的不可用, 服务功能的更改.
* 中间件更换: 上述代码使用Kafka传输信息, 但若以后更改为其他MQ, 则需要大量修改.


## 4. Scalability
评判可拓展性, 取决于当添加新的业务逻辑时, 需要新增或修改多少代码. 假设需要添加一个跨行转账的功能, 你会发现上述代码基本无法复用:
* 数据来源和数据格式: 上述代码的数据源为AccountDO, 而跨行需要从第三方服务获取, 服务间的数据格式也不可能兼容, 导致数据校验, 读写和异常处理都需要重写
* 业务逻辑: 数据格式的更改导致业务逻辑无法兼容, 最终导致代码充满if-else语句, 而越发复杂的分支逻辑最终加重开发和维护成本, 且容易造成bug
* 数据存储: 当业务逻辑变得复杂后, 新加入的逻辑可能需要对数据库schema或消息格式做出变更, 从而导致底层实现跟着重构


## 5. Testability
可测试性取决于两方面, 测试的覆盖度和测试的自动化程度. 高覆盖率会提高代码中错误出现的概率, 高自动化程度会提高测试的效率. 然而对于上述代码, 存在诸多测试的障碍:
* 测试搭建困难: 当代码中存在对数据库, 第三方服务, 中间体等外部依赖时, 想要完整测试整个项目需要所有外部服务都能跑起来
* 测试时长: 很多外部依赖属于I/O操作, 如网络请求和磁盘调度. 这种I/O调度在测试中耗时很久, 导致测试很难及时推进
* 耦合度高: 若某段代码中存在M个步骤, 每个步骤存在N种状态. 当所有步骤相互耦合时, 为了覆盖所有用例, 则需要有$M^N$个测试用例. 随着耦合步骤的增加, 测试用例的数量呈指数级增长.


## 6. Summary of Problems
之所以出现上述问题, 主要因为上述代码违反了以下几个原则:
* Single Responsibility Principle(单一性原则): 一个class只应有一个职责, 该职责被封装在class中. 换句话说, 改变class代码的原因只能有一个. 例如: 新闻编辑和报刊排版, 一个是文章的修改, 一个是排版的修改, 这两个功能应分离成两个不同的class. 上述代码中, 任何一个外部依赖的改变, 或金额计算逻辑的改变都需要修改代码.
* Open–closed principle(开放封闭原则): 开放拓展, 封闭修改. 上述代码中, 金额计算可能属于被修改的代码, 因此应被包装成一盒不可修改的计算class, 所有新功能通过计算类的拓展实现.
* Dependency Inversion Principle(依赖反转原则): 要求在代码中依赖抽象, 而不是具体实现. 上述代码中, Yahoo提供的汇率服务就是一个具体实现, 而不是一个抽象, Kafka也是相同道理.


## 7. What is DDD
DDD并不是一套框架, 而不是一种架构思想. 随着SOA(Service-oriented architecture)的崛起, microservice的概念开始冒头, DDD的思想可以为拆分服务提供了一套合理框架. DDD的思想让开发者去思考, 什么应被拆分为一个service, 如何降低业务逻辑与外部依赖的耦合. 这样才能减少维护成本, 提高开发效率.
