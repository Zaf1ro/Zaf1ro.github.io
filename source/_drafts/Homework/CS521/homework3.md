---
title: CS521-homework3
category:
  - Homework
tag:
  - Homework
abbrlink: 4228874263
date: 2017-09-28 16:30:34
---

* Name: Jiaxu Duan
* CWID: 10427009


### 1. Try SMTP interaction for yourself
```powershell
telnet smtp.qq.com 25
220 smtp.qq.com Esmtp QQ Mail Server
helo jason
250 smtp.qq.com
auth login
334 VXNlcm5hbWU6
MTAzNjMyNjU4Ng==
334 UGFzc3dvcmQ6
MTIzNDU2Nzg5MA==
235 Authentication successful
mail from:<1035326586@qq.com>
250 Ok
rcpt to:<1036326586@qq.com>
250 Ok
data
354 End data with <CR><LF>.<CR><LF>
from:<992014714@qq.com>
to:<1274096233@qq.com>;<1375333986@qq.com>
subject:hello!

My name is Jiaxu Duan
.
250 OK
```



### 2. p11 Now suppose that the link is shared by Bob with four other users. Bob uses parallel instances of non-persistent HTTP, and the other four users use non-persistent HTTP without parallel downloads.
1. Do Bob’s parallel connections help him get Web pages more quickly?
Yes. For single page, bob has more connection, so he can get more bandwidth than other users.

2. If all five users open five parallel instances of non-persistent HTTP, then would Bob’s parallel connections still be beneficial?
No, because five users share five connections, so bob cannot get any benefits from parallel.



### 3. p12 Write a simple TCP program for a server that accepts lines of input from a client and prints the lines onto the server’s standard output.
```java
import java.io.*;
import java.net.*;

class TCPServer {
    public static void main(String argv[])
    {
        String s;
        String ;
        ServerSocket MySocket = new ServerSocket(8080);

        while(true) {
            Socket connectionSocket = MySocket.accept();
            BufferedReader buffer = new BufferedReader(
                new InputStreamReader(connectionSocket.getInputStream())
            );

            DataOutputStream outToClient = new DataOutputStream(connectionSocket.getOutputStream());
            s = buffer.readLine();
            outToClient.writeBytes(s.toUpperCase() + '\n');
        }
    }
}
```



### 4. p13 What is the difference between MAIL FROM: in SMTP and From: in the mail message itself?
"MAIL FROM" in SMTP is to vertify sender is in the allowed list
"FROM" in mail messafe is for mail sender to know who send this email



### 5. p19 we use the useful dig tool available on UNIX and Linux hosts to explore the hierarchy of DNS servers. Recall that in Figure 2.21
1. Starting with a root DNS server, initiate a sequence of queries for the IP address for your department’s Web server by using dig. Show the list of the names of DNS servers in the delegation chain in answering your query.
```powershell
> dig +norecurse @a.root-servers.net any stevens.edu

; <<>> DiG 9.8.3-P1 <<>> +norecurse @a.root-servers.net any stevens.edu
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 60093
;; flags: qr; QUERY: 1, ANSWER: 0, AUTHORITY: 6, ADDITIONAL: 7

;; QUESTION SECTION:
;stevens.edu.			IN	ANY

;; AUTHORITY SECTION:
edu.			172800	IN	NS	f.edu-servers.net.
edu.			172800	IN	NS	a.edu-servers.net.
edu.			172800	IN	NS	g.edu-servers.net.
edu.			172800	IN	NS	l.edu-servers.net.
edu.			172800	IN	NS	c.edu-servers.net.
edu.			172800	IN	NS	d.edu-servers.net.

;; ADDITIONAL SECTION:
f.edu-servers.net.	172800	IN	A	192.35.51.30
a.edu-servers.net.	172800	IN	A	192.5.6.30
g.edu-servers.net.	172800	IN	A	192.42.93.30
g.edu-servers.net.	172800	IN	AAAA	2001:503:cc2c::2:36
l.edu-servers.net.	172800	IN	A	192.41.162.30
c.edu-servers.net.	172800	IN	A	192.26.92.30
d.edu-servers.net.	172800	IN	A	192.31.80.30

;; Query time: 21 msec
;; SERVER: 198.41.0.4#53(198.41.0.4)
;; WHEN: Thu Sep 28 22:00:46 2017
;; MSG SIZE  rcvd: 264
```

2. Repeat part a) for several popular Web sites, such as google.com, yahoo.com, or amazon.com.
```powershell
> dig +norecurse @a.root-servers.net any google.com

; <<>> DiG 9.8.3-P1 <<>> +norecurse @a.root-servers.net any google.com
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 60161
;; flags: qr; QUERY: 1, ANSWER: 0, AUTHORITY: 13, ADDITIONAL: 12

;; QUESTION SECTION:
;google.com.			IN	ANY

;; AUTHORITY SECTION:
com.			172800	IN	NS	e.gtld-servers.net.
com.			172800	IN	NS	b.gtld-servers.net.
com.			172800	IN	NS	j.gtld-servers.net.
com.			172800	IN	NS	m.gtld-servers.net.
com.			172800	IN	NS	i.gtld-servers.net.
com.			172800	IN	NS	f.gtld-servers.net.
com.			172800	IN	NS	a.gtld-servers.net.
com.			172800	IN	NS	g.gtld-servers.net.
com.			172800	IN	NS	h.gtld-servers.net.
com.			172800	IN	NS	l.gtld-servers.net.
com.			172800	IN	NS	k.gtld-servers.net.
com.			172800	IN	NS	c.gtld-servers.net.
com.			172800	IN	NS	d.gtld-servers.net.

;; ADDITIONAL SECTION:
e.gtld-servers.net.	172800	IN	A	192.12.94.30
e.gtld-servers.net.	172800	IN	AAAA	2001:502:1ca1::30
b.gtld-servers.net.	172800	IN	A	192.33.14.30
b.gtld-servers.net.	172800	IN	AAAA	2001:503:231d::2:30
j.gtld-servers.net.	172800	IN	A	192.48.79.30
j.gtld-servers.net.	172800	IN	AAAA	2001:502:7094::30
m.gtld-servers.net.	172800	IN	A	192.55.83.30
m.gtld-servers.net.	172800	IN	AAAA	2001:501:b1f9::30
i.gtld-servers.net.	172800	IN	A	192.43.172.30
i.gtld-servers.net.	172800	IN	AAAA	2001:503:39c1::30
f.gtld-servers.net.	172800	IN	A	192.35.51.30
a.gtld-servers.net.	172800	IN	A	192.5.6.30

;; Query time: 37 msec
;; SERVER: 198.41.0.4#53(198.41.0.4)
;; WHEN: Thu Sep 28 21:59:28 2017
;; MSG SIZE  rcvd: 504
```
