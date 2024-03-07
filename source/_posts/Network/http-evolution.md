---
title: Evolution of HTTP 
category:
  - Network
tag:
  - Network
abbrlink: '3759'
date: 2016-05-30 21:38:05
---

## 1. TCP
1. 通过ACK确认receiver(接收方)是否收到数据, 从而提供`可靠`连接
2. ACK还实现了**sliding window**, 接收方可告知发送方是否增加或减少发送速率, 从而避免网络拥塞
3. TCP keepalive: 即使长时间没有数据交换, TCP仍允许connection保持活动状态


## 2. HTTP 0.9 and HTTP 1.0
### HTTP 0.9 
* 基于TCP连接, HTTP无需担心数据是否传输成功
* TCP面向packet, 而HTTP面向connection
* HTTP request中只有GET方法和资源地址, 如`GET /mypage.html`
* HTTP response中只有HTML文件
* 无连接: 每次HTTP连接只处理一个请求, 处理完立即关闭连接
* 无状态: HTTP连接没有记忆, 换句话说, 前后两次连接没有任何关系

### HTTP 1.0
* GET方法加入版本信息: `HTTP/1.0`
* 引入HTTP Header: HTTP request和response都包含HTTP Header
* HTTP response的header引入Content-Type, 从此HTTP response可返回除HTML之外的文件
* 引入Status Code(状态码), 从此浏览器可判断请求是否成功
* 引入POST和HEAD方法

### Summary
HTTP 1.0相对于HTTP 0.9的最大区别在于HTTP Header, 从此client可请求不同类型的文件; HTTP 0.9始于上世纪九十年代, 当时的服务器性能无法同时支持过多TCP连接, 因此HTTP 0.9/1.0的很多设计以此为前提; 但随着硬件的不断发展, 服务端和客户端提出了更多业务要求:
* 安全性低: 明文通信会被中间人窃听, 且client无法验证对方身份
* 效率低下: 无连接特性导致TCP连接频繁中断
* 实时通信: Server无法主动向client发信息, 只能采取client轮询机制, 导致大量连接建立并断开
* 并发受限: 单个client向同一域名发起的并发连接数量有限


## 3. HTTP 1.1
HTTP 1.1与HTTP 1.0只间隔几个月, 最初的HTTP 1.1只有以下更新:
* 持久连接: 由于HTTP 1.0会在请求结束后立即断开连接, HTTP1.1添加`Keep-Alive`(保持连接)以保持连接, 从而减少频繁的TCP分手和握手, 并减少慢启动的时间
* 分块加载: 引入**Chunked Eesponse**(分块响应), 发送大文件时, 可将HTTP response拆分为多个更小的chunk, 从而不必发送整个文件
* 无需等待: 引入**HTTP Pipelining**(HTTP管线化), 让多个HTTP request同时提交, 让下一个request不必等待上一次request的response
* 内容协商: 引入language, encoding, type等HTTP Header, 让client和server就如何交换内容达成一致
* 缓存控制: 引入Cache-Control, 允许server决定资源缓存时间

### Extensions of HTTP 1.1
HTTP 1.1始于RFC 2068, 并在接下来的十几年间进行多次更新(RFC 2616, RFC 7230, RFC 7235):
* SSL: 在TCP和HTTP之间加入了SSL, 加密信息以保证server和client间交换的消息不会被第三方获取
* HTTP Method: 引入更多HTTP方法, 如PUT, PATCH, DELETE, CONNECT, TRACE, OPTIONS
* WebSocket: 实现client和server的双向通信, 让server可以向client发送信息

### Cons of HTTP Pipelining
由于HTTP pipelining规定server必须依次回复request, 这就导致了`对头阻塞`(HOL blocking), 因为超时的response可能会导致后面的response阻塞. 
并且部分server和大部分proxy都不支持pipelining, server的错误支持会导致client端出现异常, 并且在性能上并没有太大提升, 所以很多浏览器默认关闭了pipelining.
并且只有GET和HEAD类型的request能被pipelining化, 其他类型的request不可以(例如: POST).


## 4. Reduce Response Time in HTTP 1.x
HTTP 1.x存在如下特性:
* 传输文本格式信息, 可读性好但消息传递效率低
* 不支持双工通信
* 多个资源请求需发送多次请求

HTTP 1.x环境下的相应解决方案:
* 使用websocket实现双工通信
* 将动态页面与静态资源分离
* 将体积较大的视频和图片缓存到CDN

### 4.1 spliting
由于HTTP1.1中使用单个连接依次发送请求, 并且TCP的慢启动特性, 导致传输一个大文件比传输多个小文件快得多(大文件的文件大小与小文件总共大小相同).server端可以将多个需要传输的文件拼接成一个大文件直接传输给client, 然后通过JS或CSS裁剪成需要的小图片.

### 4.2 inlining
与spriting相同, 可将图片的原始数据写入CSS之中, 通过传输一个较大的CSS来传输多个图片文件
```css
.icon1{
	background: url(data: image/png; base64, <data>) no-repeat;
}
```

### 4.3 concatenation
通过工具将多个JS文件合并成一个文件, 也是为了减少TCP慢启动. 但如果用户只想要JS文件中的一小部分, 那么只能全部下载, 这样也增加了时延, 且这么做对于开发不利.

### 4.4 sharding
根据[HTTP1.1标准](https://www.w3.org/Protocols/rfc2616/rfc2616-sec8.html#sec8.1.4)可知, 对同一域名建立的连接数不能超过二个, 因此无法通过并发提高速度. 但可以将服务分散在多台主机上, 同一个域名内的资源分布在不同主机名的主机上, 这样用户可以从多个主机名上获取各个资源, 用户和网站之间也就建立了更多连接, 从而减少加载时间.


## 5. HTTP 2.0
HTTP 2.0的主要目标是提升协议性能: 在兼容HTTP的前提下, 提高传输性能, 实现低延迟和高吞吐量. 以下是HTTP 2.0的更新:
* 二进制协议: 可读性差, 但信息传输效率更高
* 多路复用: HTTP2允许单个连接中client发起多个请求, 不会因为某个超时请求导致后续请求无法及时发送, 这样不会发生HTTP1.1的线头阻塞
* 二进制分帧: HTTP 2.0中的一次连接可发送多个**stream**, 每个stream包含一个**message**(request或response), 每个message包含两个**frame**, 其中HTTP Header被封装到HEADER frame中, Request Body部分封装到DATA frame中. 由于TCP存在慢启动, 导致短时间的HTTP连接十分低效, 因此可使用同一TCP连接实现低延迟
* 首部压缩: HTTP2.0使用**DEFLATE**算法压缩HTTP Header, 从而提高带宽效率
* 服务器推送: HTTP1.x中server只能针对client的一个request回复一个response. HTTP2中server可以对client的request发送多个response. 这样client在请求一个页面时就可以获取所有资源(HTML, CSS和其他资源), 从未减少了往返时间
