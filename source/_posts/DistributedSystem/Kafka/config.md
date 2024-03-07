---
title: Kafka Configuration
tags:
  - Kafka
category:
  - Kafka
abbrlink: eef
date: 2024-03-05 15:21:55
keywords:
description:
---

## Producer Configuration
### 1. Mandatory Properties
#### bootstrap.servers
该属性为`host:port`格式的列表, 表示producer与Kafka集群初次建立连接时所需的broker列表. 该属性不必包含所有broker, 但推荐包含至少两个broker地址, 若其中一个broker宕机, 可连接另外一个broker.

#### key.serializer
该属性为一个class名称, 用于序列化record的key. 任何Java object都可作为key, 因此serializer必须知道如何将object转换为byte array, 因此该属性对应的class应实现`org.apache.kafka.common.serialization.Serializer`接口. kafka client已经提供了一个serializer, `如ByteArraySerializer`, `String​Serial⁠izer`, `IntegerSerializer`, `VoidSerializer`. 即使record中的key为空, 也必须设置属性.

#### value.serializer
该属性为一个class名称, 用于序列化record的value. 


### 2. Optional Properties
#### client.id
该属性可为任意字符串, 表示client的标识符. Broker用其区分不同的client, 通常用于日志记录和配额. 推荐将该属性配置为client所处的服务名称, 如`order service`. 默认为空字符串.

#### acks
该属性表示在producer认为写入成功前, 需有多少个partition replica接收到该record. 默认情况下, 当leader接收到record时, client就认为该record已成功写入. 以下是该属性的三种选项:
* `ack=0`: producer不等待任何broker回复, 默认信息成功发送, 因此producer不知道信息是否发送至broker, 虽然可能发生信息丢失, 但信息吞吐量最高.
* `ack=1`: leader replica收到信息并回复producer时, producer认为信息已成功写入; 若leader宕机或还没选举出leader, producer会受到错误回复, 并重新发送信息. 若leader收到信息后宕机, 但信息还没复制到其他replica, 则信息丢失.
* `acks=all`: 所有sync replica都受到信息时, producer认为信息已成功写入. 该选项可确保即使leader宕机, 信息依然不会丢失, 但延迟最高, 因为producer需等待所有replica收到信息.

需要注意的是, 该选项只影响`producer latency`, 不影响`end-to-end latency`. Producer latency表示从`producer生成一个record`, 到`producer确认该消息写入Kafka集群`的时间; end-to-end latency表示从`producer生成一个record`, 到`consumer可读取该record`的时间. 由于一条record只有被所有replica写入后才能被consumer消费, 因此上述三个选项的end-to-end latency相同.

#### max.block.ms
该属性针对两个KafkaProducer的两个函数:
* `send()`: 获取metadata和申请buffer的最长时长
* `partitionFor()`: 当metadata不可用, 等待新的metadata的最长时长

若调用上述函数时, 对应的操作阻塞达到该属性指定的时长, 则返回timeout exception.

#### request.timeout.ms
该属性规定了从`producer发送数据`到`接收到broker的响应`之间的最大时长, 不包括重试时间. 若超出该时长, 则返回timeout exception.

#### linger.ms
该属性规定了发送batch前等待下一条消息的最长时长. producer在生成一条消息后不会立即发送, 而是一次发送多个消息, 从而降低网络; 但producer无法确定下一条消息何时生成, 若等待时间超过该属性, 则直接发送当前batch.

#### delivery.timeout.ms
该属性规定了从`send()成功返回`(将record放入batch中)到`broker响应或producer放弃重试`之间的最大时长, 其中包括重试所需的时间. 该属性需大于`linger.ms`和`request.timeout.ms`, 否则返回exception. 若重试时超出该属性值, 则抛出重试之前错误对应的exception; 若还没重试前就超出属性值, 则返回timeout exception.

#### retries
该属性表示producer在放弃向broker发送前需重试多少次. 需要注意的是, 并不是错误都会让producer重试, 若消息大小超出阈值, 则producer不会重试. 若不想让producer重试, 则设置`retries=0`.

#### retry.backoff.ms
该属性表示每次重试的间隔时间, 避免在某些故障发生时重复发送请求.

#### buffer.memory
该属性为producer用于临时存放消息的内存大小, 若消息发送速率比消息生成速度低, 则会导致buffer耗尽, 下次调用`send()`时会阻塞进程, 直到超过`max.block.ms`时间并抛出exception.

#### compression.type
该属性为producer压缩消息的算法, 默认不压缩, 可选项为`snappy`, `gzip`, `lz4`和`zstd`.
* snappy: CPU负载低, 且压缩率优秀
* gzip: CPU负载高, 但压缩率最高

#### batch.size
该属性为一个batch的最大内存大小. batch中消息的总内存量超过该属性时, producer会立即发送该batch; 但即使调高该属性值, producer也不会一直等待, 而是等待`linger.ms`时长后发送batch.

#### max.in.flight.requests.per.connection
该属性为producer可以同时发送的batch数量, 该属性值越高, producer的吞吐量越大. 需要注意的是, 若该属性值大于1且`entries`不为0, 则可能无法保证一个partition内的消息顺序存储: 假设producer先发送消息A, 之后发送消息B, A由于网络故障而发送失败, B成功被broker写入partition, producer再次尝试发送A并成功被broker写入. 两条消息都被成功写入, 但写入顺序与发送顺序颠倒, 导致consumer也会按照错误顺序消费. 为保证顺序一致性, 可设置`enable.idempotence=true`, 这样可以保证在最多5个并发请求的情况下依然保证顺序一致, 且不会因重试产生重复写入.

#### max.request.size
该属性为单个请求的最大大小, 既表示单个消息的最大值, 也表示单个请求的最大值. 默认下该属性为1MB, 因此可以发送一个1MB大小的消息, 也可以发送包含1024个1KB大小消息的batch. 需要注意的是, broker端也会限制可收到消息的最大值(`message.max.bytes`), 超出大小会被broker拒绝.

#### receive.buffer.bytes and send.buffer.bytes
该属性为TCP send/receive buffer的大小, 若设置为-1, 则使用操作系统的默认值.

#### enable.idempotence
从0.11版本开始, kafka支持**exacylt once**语义, 将该属性设置为`true`可保证producer端生成消息的顺序和broker端的写入顺序相同, 且不会造成重复写入(若producer发送后, leader写入消息并宕机, producer未收到确认并再次发送消息, 新的leader会返回`DuplicateSequenceException`).
