---
title: CS521-homework8
category:
  - Homework
tag:
  - Homework
abbrlink: 1809668511
date: 2017-11-09 18:29:23
---

##### Name: Jiaxu Duan
##### ID: 10427009

#### P416 1. we consider some of the pros and cons of virtual-circuit and datagram networks
1. For a connetion-oriented network, router has to build a connection with other by some signals. And the failed node will take down all connection. For a datagram network, no signals is required for transferring data. So, a datagram network should be choosed, because it doesn't need to waste signals to build connections.
2. It should choose connection-oriented network, like VC network. Because VC can  know the characteristic of traffic to keep amount of capacity on the path.
3. It should choose datagram architecture, because VC network is designed to fina an available route when the current route is down. But in this case, the links and routers never fail, there's no need for VC to find another path for data.


#### p417 2.Consider a virtual-circuit network. Suppose the VC number is an 8-bit field.
1. 2^8 = 256
2. It can pick any VC number between 0-2^8-1. It's not possible that there are fewer VCs in progress.
3. Each link can have its own VC number from set. So a VC may have different VC number in several links. Each router has to replace the VC number when packet arrived.


#### p417 5. In answering the following questions, keep in mind that each of the existing VCs may only be traversing one of the four links
1. No extra VC number can ne assigned to the new VC number
2. It can be 2^4=16 VC numbers, such as (00,01,10,11)


#### p418 6. Why the subtle shades in terminology?
A network-layer service has to maintain state for the connection, but transport-layer service just use a connection, and router doesn't need to know the connction.


#### p419 10. Consider a datagram network using 32-bit host address
1. Provide a forwarding table

Prefix Match | Link Interface
----|----
11100000 00 | 0
11100000 01000000 | 1
1110000 | 2
11100001 1 | 3
default | 3

2. Describe how your forwarding table determines the appropriate link interface for datagrams with destination addresses
11001000 10010001 01010001 01010101 - default - Interface 3
11100001 01000000 11000011 00111100 - 1110000 - Interface 2
11100001 10000000 00010001 01110111 - 111000011 - Interface 3


#### P420 11. For each of the four interfaces, give the associated range of destination host addresses and the number of addresses in the range

Interface | Prefix Match | Address range
-----|-----|-----
0 | 00 | 0000 0000 - 0011 1111
1 | 010 | 0100 0000 - 0101 1111
2 | 011 | 0110 0000 - 0111 1111
2 | 10 | 1000 0000 - 1011 1111
3 | 11 | 1100 0000 - 1111 1111
