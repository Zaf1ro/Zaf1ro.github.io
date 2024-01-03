---
title: HTTPS
category:
  - Network
  - Protocol
tag:
  - Protocol
abbrlink: 3382880022
date: 2017-05-19 03:04:52
---
TLS1.0
TLS协议包含两层: TLS记录协议(Record Protocol)和TLS握手协议(Handshake Protocol). TLS提供的安全连接有两个基本属性:
* 连接是私有的. 对称加密算法(例如:DES, RC4)用于数据加密. 每一次连接的密钥(key)都是唯一的, 并且是基于其他协议的(例如: TLS Handshake Protocol)而秘密协商出来的. Record Protocol可不使用加密.
* 连接是可靠的. 信息传输中使用keyed MAC(Message Authentication Code, 消息验证码)来保证数据的完整性. MAC是可选的, 但当使用Record Protocol交换安全参数时, MAC是必选的.

Record Protocol用于包裹更高层的协议, 其中一个被包裹的协议就是Handshake Protocol, 它允许Server和Client之间能认证对方, 并在传输和接受数据前协商出一个加密算法和密钥. Handshake Protocol提供的安全连接有三个基本属性:
* 对方的身份认证通过对称加密算法(例如: RSA, DSS). 认证是可选的, 但至少有一方被认证才可省略另一方的认证.
* 关于公共密钥的协商是安全的: 


HTTP over TLS

1. 连接开始
作为HTTP的user agent也应作为TLS的agent, 应以在适当的接口上建立连接并发出TLS ClientHellol来开始TLS handshake. 当handshake完成后再初始化第一个HTTP request. 所有的HTTP data都应作为TLS的"application data"进行传输. 接下来就是正常的HTTP连接行为.

2. 连接结束

