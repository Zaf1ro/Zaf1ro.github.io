## Why Company
#### 考点
* 对公司/产品的了解程度
* 对自己未来的职业规划
* 能为公司贡献什么
* 自己能获得什么

#### 准备
1. 了解公司的**产品**(及其产业)和**技术栈**(JD)
2. 思考自己的工作经验能给公司带来什么
3. 自己从中能获得什么

#### 问题模板
* Why you choose XXX?
* Why you want to make a move
* What are you looking for your next role?

#### 答题模板
陈述公司的产品, 发现了某些技术, 自己过去应用过该技术, 想要解决公司的现有问题, 从中能学到新的技术/解决新的问题


## Customer Obssession
#### 考点
* 讲的故事是否体现了你从客户的角度思考并解决问题
* customer既可以是end user, 也可以是其他team

#### 1.1 问题
明白客户需求, 并解决需求:
* Tell me a time when you made a suggestion for clients

#### 1.2 答案模板
* 如何主动发现了问题
* 生成了什么计划
* 实现过程中做了什么事
* 产生了什么结果

#### 例子
* 发现主页的workspace加载页面过慢, 且主页是访问量最高的网站
* 尝试优化, 发现是sql问题
* 进行了索引优化
* 页面加载速度提升了200%

#### 2.1 问题
* When you're working with a large number of customers, it's tricky to deliver excellent service to them all. So how do you go about prioritzing your customers' needs?

#### 2.2 例子
* 当前存在多个项目目标需要实现:
    * 客户反馈的bug: 需3-4天修复, 影响客户进行下一步操作
    * 新的feature: 需一个月时间, 可让所有用户获得更好的用户体验
    * 数据库connection优化: 增加代码可读性, 需二周实现并测试
* 跟领导讨论, 将所有项目需求分为紧急且重要, 不紧急但重要, 不紧急且不重要:
    * 优先修改客户反馈的bug
    * 再专注于新feature的delivery
    * 最后进行数据库connection优化

#### 3.1 进阶问题
* When do you think it's ok to push back or say no to an unreasonable customer request?
* Give me an example of a time when you didn't meet a client's expection. What happened, and how did you attempt to rectify the situation?

#### 3.2 答案模板
* 自己/客户提出需求
* 实施计划
* 发现客户的需求不make sense
* 跟客户交流
* 客户反馈
* 最终结果

#### 3.3 例子
* 客户希望移除已经被archived的workspace
* 我统计了所有被archived的workspace, 发现其中与active的workspace仍有共享数据
* 与客户交流, 发现客户只是觉得archived workspace影响操作效率
* 向客户提出: 隐藏archived workspace, 而不是删除这部分数据
* 客户可通过select button选择是否显示archived workspace


## Are Right, A Lot
#### 考点
* 面对信息不够时如何做决定
* 面对deadline如何做决定

#### 1.1 问题模板:
* Tell me about a time you failed/were wrong/made a mistake/had an error in judgement/made a bad decision.

#### 1.2 答案模板:
* 开发目标是什么
* 部署后谁发现了什么问题
* 问题多严重
* 如何修复
* 学到了什么
* 如何避免以后再犯错

#### 1.3 例子
* 开发目标: build database connection between typescript based server and IBM db2
* 开发中遇到问题: 由于没有官方支持的API interface, 我们采用第三方库, 但需手动配置driver license, 且缺失很多db connection config
* 解决方案: 创建一个独立服务, 使用spring boot和IBM Db2 JDBC Driver连接数据库, 并使用gRPC交换数据
* 学到什么: 使用第三方库之前需查看是否符合项目需求, 并在

#### 2.1 问题模板:
* Tell me about a time you disagreed with a colleague or boss. What is the process you used to work it out?

#### 2.2 答案模板:
* 冲突的由来: 开会讨论
* 冲突点: 产品设计/技术分歧
* 为什么你认为应该这样
* 同时你也理解别人为何要那样
* 什么方案可以解决争端: 实验验证/测试
* 对于别人的需求, 如何兼容
* 自己是对的: 别人对你的评价, 对产品的影响(量化)
* 自己是错的: 学到了什么, 如何避免类似错误

#### 2.2 例子
* 冲突的由来: 公司要求使用最新开发的UI design system
* 冲突点: 有些开发者认为应直接使用react component取代JSP markup, 但我认为这样做 应
* 为什么你这么认为: 全部替换为reacct component会产生很多unexpected error, 且开发时间漫长
* 为什么理解别人那么做: react component is easier for developers to build and maintain complex frontend applications
* 如何验证: 尝试对一些页面进行修改, 发现全部重写为react component会非常复杂, 且需要修改后端
* 如何兼容他人需求: 只修改少数业务逻辑复杂的页面, 方便后续的网页维护和功能拓展, 其他页面仍使用JSP
* 影响: 在开发时间允许的条件下, 统一网站的设计风格, 并提升用户体验


## Ownership
考察你对日常工作的负责任和态度, 不论这个工作是不是你的work, 你都乐意dive in, 发现问题并尝试解决问题. 两点需要注意:
* 故事中的问题是out of your scrope
* 故事中的你是发现问题, 解决问题的主角

#### 1.1 问题模板
* Provide an example of when you personally demonstrate ownership
* Tell me about a time you went above and beyond
* Describe a project or idea that was implemented primarily because of your efforts

#### 1.2 答案模板
* 
