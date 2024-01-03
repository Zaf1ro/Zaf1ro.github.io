---
title: HTTP vs. HTTPS vs. HTTP2
category:
  - Network
tag:
  - Network
abbrlink: '3759'
date: 2016-05-30 21:38:05
---

## 1. TCP
### 优点
1. 通过ack确认, 重传提供`可靠`连接
2. 通过`拥塞控制`保持网络性能


## 2. HTTP1.0
### 2.1 优点
* client/server模式
* 简单: client只需要请求方法和路径就可请求服务
* 灵活: 传输的文件类型众多, 只需要在content-type中指定
* 无连接: 每次连接只处理一个请求, 处理完就关闭连接
* 无状态: 事务处理没有记忆能力, 后续处理需要前面的信息时则需要重传

### 2.2 缺点
1. 安全性低
通信为明文, 可被中间人窃听, 无验证通信方身份功能
2. 效率低下
头部信息冗余, 无连接导致的频繁连接中断
3. 实时通信问题
server无法主动向client发信息(例如: 聊天窗口, server无法通知client有其他用户呼叫该client ,只能自行创建心跳机制)
4. 并发连接受限
单个客户端对同一域名的并发连接量有限, 根据浏览器不同而不同.

浏览器 | HTTP1.1 | HTTP1.0
-----|-----|-----
IE6,7 | 2 | 4
IE8 | 6 | 6
IE9 | 6 | 6
IE10 | 6 | 6
Firefox | 6 | 6
Safari | 4 | 4
Chrome | 6 | 6
Opera | 4 | 4


## 3. HTTP1.1
### 3.1 优点:
1. 持久连接
由于HTTP1.0会在一次请求结束后立即断开TCP连接, HTTP1.1添加了`KeepAlive`(保持连接)来保持TCP长连接, 这样就节约了TCP频繁挥手再握手的时间, 并且减少了慢启动的时间
2. 无需等待
**HTTP Pipelining**(HTTP管线化)让多个HTTP request整批提交, 下一次request不必依赖于上一次response

### 3.2 缺点:
由于HTTP pipelining规定server必须依次回复request, 这就导致了`对头阻塞`(HOL blocking), 因为超时的response可能会导致后面的response阻塞. 
并且部分server和大部分proxy都不支持pipelining, server的错误支持会导致client端出现异常, 并且在性能上并没有太大提升, 所以很多浏览器默认关闭了pipelining.
并且只有GET和HEAD类型的request能被pipelining化, 其他类型的request不可以(例如: POST).


## 4. HTTPS
通过在HTTP下加入`SSL`层实现信息加密,这样只能通信双方进行数据读取

### 4.1 优点:
提升安全性: 解决了用户信息泄露, DNS挟持, 网页弹窗等问题

### 4.2 缺点:
* 时长: 通讯比HTTP多了12个RTT
* 处理: 需要更多CPU运力来处理密钥
* 适配: 浏览器, 前端资源, 和CDN都需要适配和优化


## 5. HTTP1.x中如何减少延迟
### 5.1 spriting(裁剪)
由于HTTP1.1中使用单个连接依次发送请求, 并且TCP的慢启动特性, 导致传输一个大文件比传输多个小文件快得多(大文件的文件大小与小文件总共大小相同).server端可以将多个需要传输的文件拼接成一个大文件直接传输给client, 然后通过JS或CSS裁剪成需要的小图片.

### 5.2 inlining(内联)
与spriting相同, 可将图片的原始数据写入CSS之中, 通过传输一个较大的CSS来传输多个图片文件
```css
.icon1{
	background: url(data: image/png; base64, <data>) no-repeat;
}
```

### 5.3 concatenation(拼接)
通过工具将多个JS文件合并成一个文件, 也是为了减少TCP慢启动. 但如果用户只想要JS文件中的一小部分, 那么只能全部下载, 这样也增加了时延;而且这么做对于开发不利.

### 5.4 sharding(分片)
根据[HTTP1.1标准](https://www.w3.org/Protocols/rfc2616/rfc2616-sec8.html#sec8.1.4)可知, 对同一域名建立的连接数不能超过二个, 因此无法通过并发提高速度. 但可以将服务分散在多台主机上, 同一个域名内的资源分布在不同主机名的主机上, 这样用户可以从多个主机名上获取各个资源, 用户和网站之间也就建立了更多连接, 从而减少加载时间.

### 5.5 升级为HTTP2
延迟过大的根本原因还是HTTP协议的固有缺点, 所以升级为HTTP2就可以解决大多数问题


## 6. HTTP2
兼容HTTP的前提下, 提高传输性能, 实现低延迟和高吞吐量

### 6.1 优点:
* 多路复用: HTTP2允许单个连接中client发起多个请求, 不会因为某个超时请求导致后续请求无法及时发送, 这样不会发生HTTP1.1的线头阻塞
* 二进制分帧: 在HTTP2.0和TCP层之间建立一个二进制分帧层, 其中HTTP1.x中的首部信息被封装到HEADER frame中, Request Body部分封装到DATA frame中. 由于TCP慢启动的原因, 导致HTTP这种短时间连接的服务十分低效, 使用同一TCP连接可以使得HTTP实现低延迟.
* 首部压缩: 由于HTTP头部过于冗长, 导致带宽无法充分利用. HTTP2.0使用DEFLATE算法压缩Header.
* 服务器推送: HTTP1.x中server只能针对client的一个request回复一个response. HTTP2中server可以对client的request发送多个response. 这样client在请求一个页面时就可以获取所有资源(HTML, CSS和其他资源), 从未减少了往返时间.
