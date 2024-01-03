---
title: CS521-homework2
category:
  - Homework
tag:
  - Homework
abbrlink: 2332602497
date: 2017-09-20 03:50:02
---

* Name: Jiaxu Duan
* CWID: 10427009


### 1. Page171 P1: True or false
1. A user requests a Web page that consists of some text and three images. For this page, the client will send one request message and receive four response messages.
`False`. Because HTTP requests that each response corresponding to each request. If there are four resource, it should be four request message instead of one request.

2. Two distinct Web pages can be sent over the same persistent connection.
`True`. Because server's IP address and port is the same one(the same domain name), these two connections should on the same persistent connection.

3. With nonpersistent connections between browser and origin server, it is possible for a single TCP segment to carry two distinct HTTP request messages.
`False`. In a non-persistent connetion, each TCP connection will be closed once it has send one message. So it should be two TCP segments.

4. The Date: header in the HTTP response message indicates when the object in the response was last modified.
`False`. "Date" is the date of when the request was created, not the modified time.

5. HTTP response messages never have an empty message body.
`False`. It may have an empty message body.


### 2. Page171 P3: Consider an HTTP client that wants to retrieve a Web document at a given URL. The IP address of the HTTP server is initially unknown. What transport and application-layer protocols besides HTTP are needed in this scenario?
1. `DNS`(UDP) lookup and relies the IP address to the browser
2. browser open a `TCP connection` to server
3. browser sends the `HTTP request` through TCP connection
4. browser receives `HTTP response` and close the TCP connection
5. browser checks the `status of that HTTP response`

### 3. Consider the following string of ASCII characters that were captured by Wireshark when the browser sent an HTTP GET message
1. What is the URL of the document requested by the browser?
URL = gaia.cs.umass.edu/cs453/index.html

2. What version of HTTP is the browser running?
version = HTTP/1.1

3. Does the browser request a non-persistent or a persistent connection?
persistent connection, because "Connection:keep-alive"

4. What is the IP address of the host on which the browser is running?
We cannot get the IP information from HTTP, it needs the information of its TCP connection.

5. What type of browser initiates this message? Why is the browser type needed in an HTTP request message?
The type of browser should be `Mozilla/5.0 Netscape 7.2`. Server have to decide which version of informaton it should send based on the information of User-Agent
 
 
### 4. P173  P8 Referring to Problem P7, suppose the HTML file references eight very small objects on the same server. Neglecting transmission times, how much time elapses with
1. Non-persistent HTTP with no parallel TCP connections?
RTT<sub>1</sub>+RTT<sub>2</sub>+...+RTT<sub>n</sub>+2RTT<sub>0</sub>+8*2RTT<sub>0</sub>=
RTT<sub>1</sub>+RTT<sub>2</sub>+...+RTT<sub>n</sub>+18RTT<sub>0</sub>

2. Non-persistent HTTP with the browser configured for 5 parallel connections?
RTT<sub>1</sub>+RTT<sub>2</sub>+...+RTT<sub>n</sub>+2RTT<sub>0</sub>+2*2RTT<sub>0</sub>=
RTT<sub>1</sub>+RTT<sub>2</sub>+...+RTT<sub>n</sub>+8RTT<sub>0</sub>

3. Persistent HTTP?
RTT<sub>1</sub>+RTT<sub>2</sub>+...+RTT<sub>n</sub>+RTT<sub>0</sub>+RTT<sub>0</sub>=
RTT<sub>1</sub>+RTT<sub>2</sub>+...+RTT<sub>n</sub>+2RTT<sub>0</sub>


### 5. P173 P9 
Information of P9:
* average object size: 850,000 bits
* average request rate: 16 requests/s
* time between request and response: 3s
![2.12](/images/Homework/521_2_1.png)
1. Find the total average response time
&Delta;=850,000/(15*1024*1024)=0.054s
average access delay = &Delta/(1-&Delta;*&beta;)=0.054/(1-16*0.054)=0.4s
total average response time = 0.4+3 = 3.4s

2. Now suppose a cache is installed in the institutional LAN. Suppose the miss rate is 0.4. Find the total response time.
new average delay = 0.054/(1-16*0.4*0.054)=0.083s
new total average response time = 0.083+3 = 3.083s
0.4*3.083=1.23s


### 6. Telnet
1. telnet cis.poly.edu 80
```html
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
                                                  <HTML><HEAD>
                                                              <TITLE>301 Moved Permanently</TITLE>
                                                                                                  </HEAD><BODY>
                                                                                                               <H1>Moved Permanently</H1>
                 The document has moved <A HREF="http://engineering.nyu.edu/academics/departments/computer/">here</A>.<P>
 </BODY></HTML>
```

2. get /~ross/
![screenshot of Wireshark](/images/Homework/521_2_2.png)