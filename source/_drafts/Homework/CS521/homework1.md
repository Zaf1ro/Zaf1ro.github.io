---
title: CS521-homework1
category:
  - Homework
tag:
  - Homework
abbrlink: 302113083
date: 2017-09-07 03:50:02
---

* Name: Jiaxu Duan
* CWID: 10427009



### 1. Page 43: "Want to try out Traceroute for yourself? "
The test environment is Stevens Wifi. I use command prompt(Win10) to execute following commands:

```powershell
C:\Users>tracert stevens.edu

Tracing route to stevens.edu [155.246.21.100]
over a maximum of 30 hops:

  1     4 ms     5 ms     4 ms  155.246.161.2
  2    13 ms     5 ms     3 ms  redirect.stevens.edu [155.246.21.100]

Trace complete.


C:\Users>tracert google.com

Tracing route to google.com [172.217.3.110]
over a maximum of 30 hops:

  1     3 ms     5 ms     3 ms  155.246.161.2
  2    25 ms     3 ms     4 ms  gwa.cc.stevens.edu [155.246.151.37]
  3     4 ms     4 ms     4 ms  454a0465.cst.lightpath.net [69.74.4.101]
  4     5 ms     4 ms     4 ms  18267502.cst.lightpath.net [24.38.117.2]
  5     7 ms     7 ms     6 ms  69.74.203.201
  6     6 ms     6 ms     9 ms  451be0b1.cst.lightpath.net [65.19.113.177]
  7     5 ms     8 ms     9 ms  72.14.215.203
  8     *        *        *     Request timed out.
  9     4 ms     4 ms     4 ms  108.170.227.245
 10     6 ms     6 ms     6 ms  sea09s17-in-f14.1e100.net [172.217.3.110]

Trace complete.
```
Specification of outputs(each column):
1. number of hop(maximum is 30)
2. round-trip delay of first ping
3. round-trip delay of second ping
4. round-trip delay of third ping
5. destination IP



### 2. Page 71 - p5
1. Suppose the caravan travels 150 km, beginning in front of one tollbooth, passing through a second tollbooth, and finishing just after a third tollbooth.
Steps:
Because the distance between first tollbooth and third tollbooth is 150km, the distance between first tollbooth and second tollbooth is 150/2=75km.
T<sub>run_on_tollbooth</sub>=75km/100kph&times;2=90mins
T<sub>each_tollbooth_service</sub>=12/60&times;10=2mins
T<sub>tollbooth_service</sub>=2&times;3=6mins
T<sub>total</sub>=90+6=96mins
Answer: 96minutes

2. Repeat (1), now assuming that there are eight cars in the caravan instead of ten. What is the end-to-end delay.
T<sub>run_on_tollbooth</sub>=75km/100kph&times;2=90mins
T<sub>each_tollbooth_service</sub>=12/60*&times;8=1.6mins
T<sub>tollbooth_service</sub>=1.6&times;3=4.8mins
T<sub>total</sub>=90+4.8=94.8mins
Answer: 94.8minutes



### 3. Page 73 - p11
Information of p10:
* d<sub>i</sub> = length = 5000km, 4000km, 1000km
* s<sub>i</sub> = propagation speed = 2.5\*10^8m/s
* R<sub>i</sub> = transmission rate of link = 2Mbps
* d<sub>proc</sub> = packet switch delay = 3msec
* packet size = 1500bytes

Information of p11:
* d<sub>i</sub> = length = 5000km, 4000km, 1000km
* s<sub>i</sub> = propagation speed = 2.5\*10^8m/s
* R<sub>i</sub> = transmission rate of link = 2Mbps
* d<sub>proc</sub> = packet switch delay = 0msec
* packet size = 1500bytes

T<sub>packet_to_link</sub> = (1500bytes\*8)/(2\*1024\*1024) = 6ms
T<sub>first_link_delay</sub> = (5000km\*10^3)/2.5\*10^8m/s = 20ms
T<sub>second_link_delay</sub> = (4000km\*10^3)/2.5\*10^8m/s = 16ms
T<sub>third_link_delay</sub> = (1000km\*10^3)/2.5\*10^8m/s = 4ms
T<sub>end_to_end_delay</sub> = 6+20+16+4 = 46ms
Answer: 46ms


### 4. Page 73 - p12
* packet size = 1500bytes
* link rate = 2Mbps

T<sub>queue_delay_per_packet</sub> = (1500bytes\*8)/(2\*1024\*1024) = 6ms
T<sub>total_queue_delay</sub> = 6\*4.5 = 27ms

* bits of the currently-being-transmitted packet: x
* number of packets in queue: n
* length of packet: L
* transmission rate: R

T<sub>queue_delay_per_packet</sub> = L/R
T<sub>total_queue_delay</sub> = L/R \* ((L-x)/L+n) = (L-x+nL)/R



### 5. Page 74 - p18
1. result of traceroute
  1. 10:00AM
  ```powershell
  Tracing route to github.com [192.30.253.113]
  over a maximum of 30 hops:

    1     5 ms     3 ms     4 ms  155.246.161.2
    2     8 ms     6 ms     4 ms  gwa.cc.stevens.edu [155.246.151.37]
    3     4 ms     4 ms     4 ms  454a0465.cst.lightpath.net [69.74.4.101]
    4     4 ms     4 ms     4 ms  18267502.cst.lightpath.net [24.38.117.2]
    5     8 ms     7 ms     7 ms  41332aa5.cst.lightpath.net [65.51.42.165]
    6     7 ms     8 ms    14 ms  hunt183-209.optonline.net [167.206.183.209]
    7    10 ms     8 ms    10 ms  451be09e.cst.lightpath.net [65.19.113.158]
    8     *        *        8 ms  lag-102.ear1.Newark1.Level3.net [4.35.20.29]
    9     *        *        *     Request timed out.
  10    12 ms    12 ms    14 ms  GITHUB-INC.bear1.Washington111.Level3.net [4.53.116.102]
  11     *        *        *     Request timed out.
  12     *        *        *     Request timed out.
  13    14 ms    12 ms    14 ms  lb-192-30-253-113-iad.github.com [192.30.253.113]

  Trace complete.
  ```
  2. 02:00PM
  ```powershell
  Tracing route to github.com [192.30.253.113]
  over a maximum of 30 hops:

    1     9 ms     2 ms     5 ms  155.246.161.2
    2    25 ms    21 ms     7 ms  gwa.cc.stevens.edu [155.246.151.37]
    3    10 ms     9 ms     9 ms  454a0465.cst.lightpath.net [69.74.4.101]
    4   113 ms   207 ms   200 ms  18267502.cst.lightpath.net [24.38.117.2]
    5    26 ms    11 ms    15 ms  41332aa5.cst.lightpath.net [65.51.42.165]
    6     8 ms    15 ms    12 ms  hunt183-209.optonline.net [167.206.183.209]
    7    12 ms    12 ms    14 ms  451be09e.cst.lightpath.net [65.19.113.158]
    8     *       73 ms    81 ms  lag-102.ear1.Newark1.Level3.net [4.35.20.29]
    9     *        *        *     Request timed out.
  10    41 ms    21 ms    20 ms  GITHUB-INC.bear1.Washington111.Level3.net [4.15.136.22]
  11     *        *        *     Request timed out.
  12     *        *        *     Request timed out.
  13    15 ms    16 ms    20 ms  lb-192-30-253-113-iad.github.com [192.30.253.113]

  Trace complete.
  ```

  3. 10:00PM
  ```powershell
  C:\Users>tracert github.com

  Tracing route to github.com [192.30.253.113]
  over a maximum of 30 hops:

    1     3 ms     3 ms    11 ms  155.246.161.2
    2     5 ms     5 ms     3 ms  gwa.cc.stevens.edu [155.246.151.37]
    3     5 ms    11 ms     5 ms  454a0465.cst.lightpath.net [69.74.4.101]
    4    10 ms     7 ms     4 ms  18267502.cst.lightpath.net [24.38.117.2]
    5     7 ms     7 ms     8 ms  41332aa5.cst.lightpath.net [65.51.42.165]
    6    10 ms     7 ms    11 ms  hunt183-209.optonline.net [167.206.183.209]
    7     9 ms    10 ms    12 ms  451be09e.cst.lightpath.net [65.19.113.158]
    8     *        9 ms     9 ms  lag-102.ear1.Newark1.Level3.net [4.35.20.29]
    9     *        *        *     Request timed out.
  10    16 ms    12 ms    11 ms  GITHUB-INC.bear1.Washington111.Level3.net [4.53.116.102]
  11     *        *        *     Request timed out.
  12     *        *        *     Request timed out.
  13    14 ms    14 ms    13 ms  lb-192-30-253-113-iad.github.com [192.30.253.113]

  Trace complete.
  ```

2. Find the average and standard deviation of the round-trip delays at each of the three hours.
  1. T<sub>avg</sub>=(14+12+14)/3&asymp;13.3
     T<sub>sd</sub>=&radic;((0.7^2+-1.3^2+0.7^2)/3)&asymp;0.94
  2. T<sub>avg</sub>=(15+16+20)/3=17
     T<sub>sd</sub>=&radic;((2^2+1^2+3^2)/3)&asymp;2.16
  3. T<sub>avg</sub>=(14+14+13)/3&asymp;13.7ms
     T<sub>sd</sub>=&radic;((0.3^2+0.3^2+0.7^2+0.5^2)/4)&asymp;0.47

3. Find the number of routers in the path at each of the three hours. Did the paths change during any of the hours?
  1. N<sub>r1</sub>=13
  2. N<sub>r2</sub>=13
  3. N<sub>r3</sub>=13
  It didn't change any path in the three paths.

4. Do the largest delays occur at the peering interfaces between adjacent ISPs?
  No, there were no large delay

5. Repeat the above for a source and destination on different continents.
  1. Amazon in asian
    1. T<sub>avg</sub>=(337+321+335)/3=331
      T<sub>sd</sub>=&radic;((6^2+10^2+4^2)/3)&asymp;7.1
    2. T<sub>avg</sub>=(336+321+329)/3&asymp;329
      T<sub>sd</sub>=&radic;((7^2+8^2+0^2)/3)&asymp;6.1
    3. T<sub>avg</sub>=(340+320+336)/3=332
      T<sub>sd</sub>=&radic;((8^2+12^2+4^2)/3)&asymp;8.6
  2. Amazon in america
    1. T<sub>avg</sub>=(17+13+19)/3&asymp;16
      T<sub>sd</sub>=&radic;((1^2+3^2+3^2)/3)&asymp;4.4
    2. T<sub>avg</sub>=(7+8+9)/3=8
      T<sub>sd</sub>=&radic;((1^2+0^2+1^2)/3)=0.8
    3. T<sub>avg</sub>=(6+15+10)/3&asymp;10
      T<sub>sd</sub>=&radic;((4^2+5^2+0^2)/3)&asymp;3.7



### 6. Page 74 - p19
(1) Performing traceroutes from two different cities in France to the same destination host in the United States.
1. traceroute from Linkbynet (AS25593)
```powershell
Tracing route to lb-192-30-253-113-iad.github.com [192.30.253.113]
over a maximum of 30 hops:

  1    <1 ms    <1 ms    <1 ms  172.24.131.1 
  2    <1 ms    <1 ms    <1 ms  . [46.19.176.194] 
  3    <1 ms    <1 ms    <1 ms  r1-v50-s1-pa2-eqx.int.linkbynet.com [217.19.56.41] 
  4     1 ms    <1 ms     1 ms  ae0-103.cr0-par7.ip4.gtt.net [77.67.94.65] 
  5     1 ms     1 ms     1 ms  xe-1-2-0.cr0-par9.ip4.gtt.net [141.136.109.1] 
  6     1 ms     1 ms     1 ms  ae-12.r02.parsfr02.fr.bb.gin.ntt.net [46.33.84.54] 
  7    13 ms    14 ms    13 ms  ae-10.r24.amstnl02.nl.bb.gin.ntt.net [129.250.2.196] 
  8    14 ms    13 ms    13 ms  ae-3.r25.amstnl02.nl.bb.gin.ntt.net [129.250.4.69] 
  9    83 ms    83 ms    83 ms  ae-5.r23.asbnva02.us.bb.gin.ntt.net [129.250.6.162] 
 10    82 ms    82 ms    82 ms  ae-2.r05.asbnva02.us.bb.gin.ntt.net [129.250.2.22] 
 11    83 ms    82 ms    82 ms  ae-0.a01.asbnva02.us.bb.gin.ntt.net [129.250.5.182] 
 12    95 ms    96 ms    95 ms  xe-0-0-25-1.a01.asbnva02.us.ce.gin.ntt.net [128.241.3.22] 
 13     *        *        *     Request timed out.
 14     *        *        *     Request timed out.
 15    84 ms    83 ms    83 ms  lb-192-30-253-113-iad.github.com [192.30.253.113] 

Trace complete.
```

2. Hosting France (AS31555)
```powershell
Tracing route to: 192.30.253.113

traceroute to 192.30.253.113 (192.30.253.113), 30 hops max, 60 byte packets
 1  fw-55-1.netsample.com (185.133.55.1)  0.161 ms  0.094 ms  0.098 ms
 2  185.133.52.252 (185.133.52.252)  2.666 ms  2.654 ms  2.642 ms
 3  78.153.240.108 (78.153.240.108)  2.049 ms  2.036 ms  2.043 ms
 4  ge501-0-0-34.er02.mar01.jaguar-network.net (193.151.86.40)  1.110 ms  1.160 ms  1.150 ms
 5  185.84.18.25 (185.84.18.25)  0.723 ms  0.714 ms  0.785 ms
 6  ae-1.r24.amstnl02.nl.bb.gin.ntt.net (129.250.4.90)  20.860 ms  20.900 ms  20.817 ms
 7  ae-3.r25.amstnl02.nl.bb.gin.ntt.net (129.250.4.69)  20.830 ms  21.057 ms  21.032 ms
 8  ae-5.r23.asbnva02.us.bb.gin.ntt.net (129.250.6.162)  113.735 ms  113.950 ms  113.948 ms
 9  ae-20.r06.asbnva02.us.bb.gin.ntt.net (129.250.2.133)  116.247 ms  115.793 ms  107.215 ms
10  ae-1.a01.asbnva02.us.bb.gin.ntt.net (129.250.5.188)  108.139 ms  99.339 ms  108.091 ms
11  xe-0-0-25-1.a01.asbnva02.us.ce.gin.ntt.net (128.241.3.22)  114.036 ms  107.261 ms  107.209 ms
12  * * *
13  * * *
14  lb-192-30-253-113-iad.github.com (192.30.253.113)  93.749 ms  102.329 ms  94.394 ms
```

3. Same link:
The transatlantic link is the same.
```sh
1. e-3.r25.amstnl02.nl.bb.gin.ntt.net (129.250.4.69)
2. ae-3.r25.amstnl02.nl.bb.gin.ntt.net (129.250.4.69)
3. ae-5.r23.asbnva02.us.bb.gin.ntt.net (129.250.6.162)
4. xe-0-0-25-1.a01.asbnva02.us.ce.gin.ntt.net (128.241.3.22)
```

(2) choose one city in France and another city in Germany
1. France - Hosting France (AS31555)
```powershell
Tracing route to: 192.30.253.113

traceroute to 192.30.253.113 (192.30.253.113), 30 hops max, 60 byte packets
 1  fw-55-1.netsample.com (185.133.55.1)  0.219 ms  0.164 ms  0.138 ms
 2  185.133.52.252 (185.133.52.252)  0.676 ms  0.667 ms  0.655 ms
 3  78.153.240.108 (78.153.240.108)  0.770 ms  0.751 ms  0.725 ms
 4  ge501-0-0-34.er02.mar01.jaguar-network.net (193.151.86.40)  1.062 ms  1.195 ms  1.028 ms
 5  185.84.18.25 (185.84.18.25)  0.763 ms  0.779 ms  0.853 ms
 6  ae-1.r24.amstnl02.nl.bb.gin.ntt.net (129.250.4.90)  20.951 ms  20.902 ms  20.930 ms
 7  ae-3.r25.amstnl02.nl.bb.gin.ntt.net (129.250.4.69)  20.881 ms  21.167 ms  22.293 ms
 8  ae-5.r23.asbnva02.us.bb.gin.ntt.net (129.250.6.162)  107.296 ms  118.344 ms  118.346 ms
 9  ae-20.r06.asbnva02.us.bb.gin.ntt.net (129.250.2.133)  107.431 ms  107.590 ms  116.029 ms
10  ae-1.a01.asbnva02.us.bb.gin.ntt.net (129.250.5.188)  108.155 ms ae-0.a01.asbnva02.us.bb.gin.ntt.net (129.250.5.182)  107.787 ms  116.522 ms
11  xe-0-0-25-1.a01.asbnva02.us.ce.gin.ntt.net (128.241.3.22)  116.125 ms  115.825 ms  107.198 ms
12  * * *
13  * * *
14  lb-192-30-253-113-iad.github.com (192.30.253.113)  99.353 ms  102.403 ms  94.016 ms

Trace complete.
```

2. Germany - SpeedKom GmbH (AS12931)
```powershell
Traceroute 192.30.253.113: traceroute to 192.30.253.113 (192.30.253.113), 30 hops max, 40 byte packets
 1  ge01-v20.kempten4.net.speedkom.net (213.182.0.119)  0.125 ms
 2  host-80-81-6-217.customer.m-online.net (80.81.6.217)  2.691 ms
 3  et-4-0-0.rt-decix-2.m-online.net (82.135.16.197)  10.401 ms
 4  213.198.72.237 (213.198.72.237)  11.148 ms
 5  ae-2.r20.frnkge04.de.bb.gin.ntt.net (129.250.5.217)  11.141 ms
 6  ae-8.r22.asbnva02.us.bb.gin.ntt.net (129.250.4.96)  95.826 ms
 7  ae-1.r05.asbnva02.us.bb.gin.ntt.net (129.250.2.20)  101.132 ms
 8  ae-1.a03.asbnva02.us.bb.gin.ntt.net (129.250.5.214)  110.134 ms
 9  xe-0-0-24-1.a03.asbnva02.us.ce.gin.ntt.net (128.241.3.30)  98.545 ms
10  *
11  *
12  lb-192-30-253-113-iad.github.com (192.30.253.113)  98.400 ms

Traceroute to 192.30.253.113 finished. 
```

3. Same Link
They don't have the same link.

(3) traceroutes to two hosts, each in a different city in China
1. China - Beijing
```powershell
Tracing route to 119.75.213.61 over a maximum of 30 hops

  1     2 ms     2 ms     2 ms  x.1.80.192.web-pass.com [192.80.1.10]
  2     3 ms     8 ms     8 ms  lo0-100.NWRKNJ-VFTTP-307.verizon-gni.net [98.109.25.1]
  3    13 ms     6 ms     6 ms  B3307.NWRKNJ-LCR-21.verizon-gni.net [100.41.206.8]
  4     *        *        *     Request timed out.
  5    71 ms    67 ms    68 ms  0.ae3.XL3.LAX1.ALTER.NET [140.222.227.113]
  6    69 ms    67 ms    67 ms  0.xe-8-3-0.GW2.LAX1.ALTER.NET [152.63.113.230]
  7    73 ms    70 ms    74 ms  ctamericas-gw.customer.alter.net [157.130.230.74]
  8    77 ms    74 ms    78 ms  202.97.50.21
  9   316 ms   313 ms   310 ms  202.97.58.125
 10     *      291 ms   290 ms  202.97.84.13
 11   330 ms   342 ms   344 ms  202.97.94.193
 12     *      310 ms     *     220.181.177.230
 13   311 ms   312 ms   318 ms  220.181.17.118
 14     *        *        *     Request timed out.
 15     *        *        *     Request timed out.
 16   326 ms   323 ms   324 ms  119.75.213.61

Trace complete.
```

2. China - Shanghai
```powershell
Tracing route to 112.90.83.112 over a maximum of 30 hops

  1     2 ms     1 ms     1 ms  x.1.80.192.web-pass.com [192.80.1.10]
  2     8 ms     4 ms     9 ms  lo0-100.NWRKNJ-VFTTP-307.verizon-gni.net [98.109.25.1]
  3     9 ms    15 ms    14 ms  B3307.NWRKNJ-LCR-21.verizon-gni.net [100.41.206.8]
  4     *        *        *     Request timed out.
  5    67 ms    67 ms    67 ms  0.ae3.XL3.LAX1.ALTER.NET [140.222.227.113]
  6    68 ms    66 ms    67 ms  0.xe-8-2-0.GW2.LAX1.ALTER.NET [152.63.113.226]
  7    79 ms    75 ms    78 ms  chinaunicom-gw.customer.alter.net [157.130.230.58]
  8   257 ms   270 ms   274 ms  219.158.102.89
  9   284 ms   262 ms   287 ms  219.158.103.37
 10   259 ms   287 ms   286 ms  219.158.8.117
 11   285 ms   278 ms   262 ms  221.4.0.174
 12     *        *        *     Request timed out.
 13     *        *        *     Request timed out.
 14     *        *        *     Request timed out.
 15   253 ms   258 ms   282 ms  112.90.83.112

Trace complete.
```

3. Same Link
Two traceroutes didn't diverge before reaching China
```powershell
lo0-100.NWRKNJ-VFTTP-307.verizon-gni.net [98.109.25.1]
B3307.NWRKNJ-LCR-21.verizon-gni.net [100.41.206.8]
B3307.NWRKNJ-LCR-21.verizon-gni.net [100.41.206.8]
0.ae3.XL3.LAX1.ALTER.NET [140.222.227.113]
```



### 7. Page 76 - p25
* length of A and B: 20000km
* R = transmission rate: 2Mbps
* propagation speed: 2.5\*10^8

1. Calculate the bandwidth-delay product
R\*d<sub>prop</sub> = 2\*10^6 * (20000&times;10^3 / 2.5\*10^8) = 1.6\*10^5bits

2. Maximun number of bits that will be in the link
&#8757; 1.6\*10^5bits < 8\*10^5bits
&there4; Maximun number of bits is 1.6\*10^5bits

3. The interpretation of the bandwidth-delay product
BDP is the maximum amount of data on the network circuit at any given time.

4. length of a bit
2.5\*10^8m/s / 2\*10^6bit/s = 125m/bit
The length of football field is 109.1m
The length of a bit is longer than football field

5. A expression for the length of a bit
s/R



### 8. Page 78 - Wireshark Lab
The screenshot of Wireshark when I use traceroute to ping `github.com`
![screenshot of Wireshark](/images/Homework/1.1_1.png)
Length: 106bytes
Source IP Address: 155.246.161.145
Destination IP Address: 192.30.253.113
Protocol: ICMP
Type: Ping
Data: 0(64bytes)
