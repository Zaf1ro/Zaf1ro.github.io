---
title: TCP handshake and Termination
category:
  - Network
tag:
  - Network
abbrlink: 9ce9
date: 2018-01-24 18:02:37
---

## 1. Status of TCP connection
### 1.1 TCP Handshake
1. LISTEN: 等待connection request
2. SYN-SENT: 发送connection request后等待ack
3. SYN-RECEIVED: 收到connection request后已发出ack, 等待final ack来确认对面收到了发出的ack
4. ESTABLISHED: 已建立connection, 可接收或发送数据

### 1.2 TCP Termination
1. FIN-WAIT-1: 未收到过对方的FIN, 自己发出FIN后等待ACK
2. FIN-WAIT-2: 此端发送完FIN并收到ACK, 等待对方发出FIN
3. CLOSE-WAIT: 收到对方的FIN, 等待application的发送FIN请求
4. CLOSING: 发出FIN后, 在收到ACK前收到对方的FIN
5. LAST-ACK: 收到过对方的FIN, 发出FIN后等待ACK
6. TIME-WAIT: 等待一段时间以确保对方收到了ACK
7. CLOSED: 连接断开

### 1.3 Reaction to RST
TCP端的全部状态可分为两种:
1. Non-synchronized state: SYN-SENT, SYN-RECEIVED
2. Synchronized state: ESTABLISHED, FIN-WAIT-1, FIN-WAIT-2, CLOSE-WAIT, CLOSING, LAST-ACK, TIME-WAIT

根据这两种情况, TCP端遇到RST时的处理方法分为两种:
1. 当 non-synchronized state 的TCP端收到RST时, 将切换到LISTEN状态
2. 当 synchronized state 的TCP端收到RST时, 将丢弃所有收到的数据, 并断开连接



## 2. TCP Handshake
### 2.1 Basic 3-Way Handshake
1. A和B都处于closed状态
2. A向B发送 SYN<sub>A</sub>
3. B收到 SYN<sub>A</sub> 后向A回复 ACK<sub>A</sub> + SYN<sub>B</sub> (ACK<sub>A</sub> = SYN<sub>A</sub> + 1)
4. A收到 ACK<sub>A</sub> 后向A回复 ACK<sub>B</sub> (ACK<sub>B</sub> = SYN<sub>B</sub> + 1)
5. A发送 ACK<sub>B</sub>+Data 到B (ACK<sub>B</sub>不变)

整个过程连接共发送了4个packet

| Step | TCP A status | Direction | Data | TCP B status|
|:-----------:|:------------:|:------------:|:------------:|:------------:|
| 1 | CLOSED      |     |                  | CLOSED 
| 2 | SYN-SENT    | ---> | `<SEQ=100><CTL=SYN>` | SYN-RECEIVED
| 3 | ESTABLISHED | <--- | `<SEQ=300><ACK=101><CTL=SYN,ACK>` | SYN-RECEIVED
| 4 | ESTABLISHED | ---> | `<SEQ=101><ACK=301><CTL=ACK>` | ESTABLISHED
| 5 | ESTABLISHED | ---> | `<SEQ=101><ACK=301><CTL=ACK><DATA>` | ESTABLISHED

### 2.2 Simultaneous Connection Synchronization
1. A和B都处于CLOSED状态
2. A向B发送 SYN<sub>A</sub>
3. B在收到 SYN<sub>A</sub> 之前向A发送 SYN<sub>B</sub>
4. A收到 SYN<sub>B</sub> 后认为自己发送的 SYN<sub>A</sub> 未被收到, 因此发送向B SYN<sub>A</sub> + ACK<sub>B</sub>
5. B收到 SYN<sub>A</sub> 后认为自己发送的 SYN<sub>B</sub> 未被收到, 因此发送向A SYN<sub>B</sub> + ACK<sub>A</sub>
6. A收到B的 ACK<sub>A</sub> 后将状态调为ESTABLISHED
7. B收到A的 ACK<sub>B</sub> 后将状态调为ESTABLISHED

连接建立完成, 整个过程共发送了4个packet
 
| Step | TCP A status | Direction | Data | TCP B status|
|:-----------:|:------------:|:------------:|:------------:|:------------:|
| 1 | CLOSED       |      |                                   | CLOSED
| 2 | SYN-SENT     | ---> | `<SEQ=100><CTL=SYN>`              | ....
| 3 | SYN-RECEIVED | <--- | `<SEQ=300><CTL=SYN>`              | SYN_SENT
| 4 | ....         | ---> | `<SEQ=100><CTL=SYN>`              | SYN-RECEIVED
| 5 | SYN-RECEIVED | ---> | `<SEQ=100><ACK=301><CTL=SYN,ACK>` | ....
| 6 | ESTABLISHED  | <--- | `<SEQ=300><ACK=101><CTL=SYN,ACK>` | SYN-RECEIVED
| 7 | ....         | ---> | `<SEQ=101><ACK=301><CTL=SYN,ACK>` | ESTABLISHED

### 2.3 Recovery from Old Duplicate SYN
1. A向B发送 SYN<sub>A</sub> 
2. B在收到 SYN<sub>A</sub>之前收到了SYN<sub>pre\_A</sub>
3. B向A发送 ACK<sub>pre\_A</sub>
4. A收到 ACK<sub>pre\_A</sub> 后发现错误, 向B发送 RST<sub>pre\_A</sub>
5. B收到 RST<sub>pre\_A</sub> 后切换状态到 LISTEN, 并在收到 SYN<sub>A</sub>后向A发送ACK<sub>A</sub>
6. A收到 ACK<sub>A</sub> 后发送 SYN<sub>A</sub> + ACK<sub>B</sub>, 并切换到ESTABLISHED
7. B收到 ACK<sub>B</sub> 后切换到ESTABLISHED

整个过程共发送6个packet (其中包括old duplicate SYN)

| Step | TCP A status | Direction | Data | TCP B status|
|:-----------:|:------------:|:------------:|:------------:|:------------:|
| 1 | CLOSED       |      |                                   | CLOSED
| 2 | SYN-SENT     | ---> | `<SEQ=100><CTL=SYN>`              | ....
| 3 | ....         | ---> | `<SEQ=90><CTL=SYN>`               | SYN-RECEIVED
| 4 | ????         | <--- | `<SEQ=300><ACK=91><CTL=SYN,ACK>`  | SYN-RECEIVED
| 5 | SYN-SENT     | ---> | `<SEQ=91><CTL=RST>`               | LISTEN
| 6 | ....         | ---> | `<SEQ=100><CTL=SYN>`              | SYN-RECEIVED
| 7 | SYN-SENT     | <--- | `<SEQ=400><ACK=101><CTL=SYN,ACK>` | SYN-RECEIVED
| 8 | ESTABLISHED  | ---> | `<SEQ=101><ACK=401><CTL=ACK>`     | ESTABLISHED

### 2.4 Half-Open Connection Discovery
假设A和B之前已经建立了连接, 并且A已经向B发送了300字节, 还剩余100字节没有发送, 此时A断开.
1. A在crash后重启socket并向B发送 SYN<sub>A</sub>
2. B由于并不知道A重启过, 所以回复 ACK<sub>300</sub> 希望获得剩余的100字节
3. A收到B的 ACK 后发现连接错误, 向B发送 RST 
4. B收到A的 RST 后中断连接
5. A重新向B发送 SYN<sub>A</sub>, 请求重新建立connection

整个过程共发送4个packet

| Step | TCP A status | Direction | Data | TCP B status|
|:-----------:|:------------:|:------------:|:------------:|:------------:|
| 1 | CRASH       |      |                               | SEND 300, RECEIVE 100
| 2 | CLOSED      |      |                               | ESTABLISHED
| 3 | SYN-SENT    | ---> | `<SEQ=100><CTL=SYN>`          | ???
| 3 | !!!         | <--- | `<SEQ=300><ACK=100><CTL=ACK>` | ESTABLISHED
| 4 | SYN-SENT    | ---> | `<SEQ=100><CTL=RST>`          | (ABORT!!!)
| 5 | SYN-SENT    |      |                               | CLOSED
| 6 | SYN-SENT    | ---> | `<SEQ=100><CTL=SYN>`          | ....

### 2.5 Old Duplicate SYN Initiate a Reset on two Passive Sockets
1. A和B都处于LISTEN状态
2. A之前发送的 SYN<sub>A</sub> 被B收到, B变为SYN-RECEIVED状态
3. B向A发送 SYN<sub>B</sub> + ACK<sub>A</sub>
4. A收到B的 SYN+ACK 后发现连接出错, 向B发送 RST
5. B收到RST后中断了连接, 并返回到LISTEN状态

整个过程共发送3个packet (其中包括A之前发送的SYN)
 
| Step | TCP A status | Direction | Data | TCP B status|
|:-----------:|:------------:|:------------:|:------------:|:------------:|
| 1 | LISTEN       |      |                                   | LISTEN
| 2 | ....         | ---> | `<SEQ=100><CTL=SYN>`              | SYN-RECEIVED
| 3 | ????         | <--- | `<SEQ=300><ACK=101><CTL=SYN,ACK>` | SYN-RECEIVED
| 4 | ????         | ---> | `<SEQ=101><CTL=RST>`              | (ABORT!!)
| 5 | LISTEN       |      |                                   | LISTEN



## 3. TCP Close
### 3.1 Normal Close 
1. A传输完其所有数据后向B发送 FIN<sub>A</sub>
2. B收到 FIN<sub>A</sub> 后回复 ACK<sub>A</sub>, 表示已经知道A发送完毕
3. B在发送完其数据后向A发送 FIN<sub>B</sub>
4. A收到 FIN<sub>B</sub> 后回复 ACK<sub>B</sub>, 并等待两个MSL后切换到CLOSED状态
5. B收到 ACK<sub>B</sub> 后切换到CLOSED状态

整个过程共发送4个packet. A之所以需要等待2个MSL, 因为B可能没有收到A的ACK, 此时B会重新发送FIN给A

| Step | TCP A status | Direction | Data | TCP B status|
|:-----------:|:------------:|:------------:|:------------:|:------------:|
| 1 | ESTABLISED |      |                                    | ESTABLISHED
| 2 | FIN-WAIT-1 | ---> | `<SEQ=100><ACK=300><CTL=FIN,ACK>`  | CLOSE-WAIT
| 3 | FIN-WAIT-2 | <--- | `<SEQ=300><ACK=101><CTL=FIN,ACK>`  | CLOSE-WAIT
| 4 | TIME-WAIT  | <--- | `<SEQ=300><ACK=101><CTL=FIN,ACK>`  | LAST-ACK
| 5 | TIME-WAIT  | ---> | `<SEQ=101><ACK=301><CTL=FIN,ACK>`  | CLOSED
| 6 | CLOSED(AFTER 2 MSL) |  |                               | CLOSED

### 3.2 Simultaneous Close Sequence
1. A向B发送 FIN<sub>A</sub> + ACK
2. B向A发送 FIN<sub>B</sub> + ACK
3. B收到A的 FIN + ACK 后回复 ACK<sub>A</sub>
4. A收到B的 FIN + ACK 后回复 ACK<sub>B</sub>
5. A和B各自收到ACK后等待2个MSL, 直接切换到CLOSED状态

整个过程共发送4个packet

| Step | TCP A status | Direction | Data | TCP B status|
|:-----------:|:------------:|:------------:|:------------:|:------------:|
| 1 | FIN-WAIT-1 | ---> | `<SEQ=100><ACK=300><CTL=FIN,ACK>` | ....
| 2 | ....       | <--- | `<SEQ=300><ACK=100><CTL=FIN,ACK>` | FIN-WAIT-1
| 3 | ....       | ---> | `<SEQ=100><ACK=300><CTL=FIN,ACK>` | CLOSING
| 4 | CLOSING    | <--- | `<SEQ=300><ACK=100><CTL=FIN,ACK>` | ....
| 5 | CLOSING    | ---> | `<SEQ=101><ACK=301><CTL=ACK>`     | CLOSING
| 6 | CLOSING    | <--- | `<SEQ=301><ACK=101><CTL=ACK>`     | CLOSING
| 7 | CLOSED(After 2 MSL) |  |                              | CLOSED(After 2 MSL)
