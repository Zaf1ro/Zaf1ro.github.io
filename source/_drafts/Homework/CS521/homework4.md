---
title: CS521-homework4
category:
  - Homework
tag:
  - Homework
abbrlink: 1651185076
date: 2017-10-05 19:02:23
---

* Name: Jiaxu Duan
* CWID: 10427009


### 1. p176 20
We can count up which web server's request appears frequently. Because more user click the website, more request for this web server will appear on the DNS cache.


### 2. p176 21
If someone in the department, the website will be cached in local DNS server. So we can use `dig` to find whether the DNS query cost time. If it cost 0 msec, it means someone had visited this website.


### 3. p177 22
F = 15 Gbits = 15 * 1024 Mbits
u<sub>s</sub> = 30 Mbps
d<sub>min</sub> = d<sub>i</sub> = 2 Mbps

* D<sub>P2P</sub> = max{F/u<sub>s</sub>, F/d<sub>min</sub>, NF/(u<sub>s</sub> + &Sigma;u<sub>i</sub>)}

* D<sub>cs</sub> = max{NF/u<sub>s</sub>, F/d<sub>min</sub>}

Client-Server

N | 10 | 100 | 1000
----|----|----|----
300Kps | 7680 | 51200 | 512000
700Kps | 7680 | 51200 | 512000
2Mbps  | 7680 | 51200 | 512000

Peer to Peer

 N | 10 | 100 | 1000
----|----|----|----
300Kps | 7680 | 25904 | 47559
700Kps | 7680 | 15616 | 21525
2Mbps  | 7680 | 7680 | 7680


### 4. p178 31
1. Suppose you run TCPClient before you run TCPServer. What happens? Why?
TCP Connection will not be made. Because client will make a connection with a non-exist server.

2. Suppose you run UDPClient before you run UDPServer. What happens? Why?
Work fine. Because UDP doesn't need to make a connection like TCP.

3. What happens if you use different port numbers for the client and server sides?
No connection. Because client and server use the differnet ports.


### 5. p178 33
Yes, you can open multiple connection on one web site.
* pro: download file faster
* con: slow down other users' download speed


### 6. p178 34
byte-stream:
* pro: byte-stream is more nutual for some applications
* con: sender need to add terminating character to split the packet

message boundries:
* pro: sender don't need to set terminating character in packet
* con: receiver cannot receive all data in one step


### 7. p181 Wireshark Lab: DNS
![DNS query](/images/Homework/521_4_1.png)


### 8. TCP & UDP (server and client)
1. TCP client
```java
import java.io.*;
import java.net.*;

class TCPClient {
 public static void main(String argv[]) throws Exception {
  String sentence;
  String modifiedSentence;
  BufferedReader inFromUser = new BufferedReader(new InputStreamReader(System.in));
  Socket clientSocket = new Socket("localhost", 6789);
  DataOutputStream outToServer = new DataOutputStream(clientSocket.getOutputStream());
  BufferedReader inFromServer = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
  sentence = inFromUser.readLine();
  outToServer.writeBytes(sentence + '\n');
  modifiedSentence = inFromServer.readLine();
  System.out.println("FROM SERVER: " + modifiedSentence);
  clientSocket.close();
 }
}
```

2. TCP server
```java
import java.io.*;
import java.net.*;

class TCPServer {
 public static void main(String argv[]) throws Exception {
  String clientSentence;
  String capitalizedSentence;
  ServerSocket welcomeSocket = new ServerSocket(6789);

  while (true) {
   Socket connectionSocket = welcomeSocket.accept();
   BufferedReader inFromClient =
    new BufferedReader(new InputStreamReader(connectionSocket.getInputStream()));
   DataOutputStream outToClient = new DataOutputStream(connectionSocket.getOutputStream());
   clientSentence = inFromClient.readLine();
   System.out.println("Received: " + clientSentence);
   capitalizedSentence = clientSentence.toUpperCase() + '\n';
   outToClient.writeBytes(capitalizedSentence);
  }
 }
}
```

3. UDP client
```java
import java.io.*;
import java.net.*;

class UDPClient
{
   public static void main(String args[]) throws Exception
   {
      BufferedReader inFromUser =
         new BufferedReader(new InputStreamReader(System.in));
      DatagramSocket clientSocket = new DatagramSocket();
      InetAddress IPAddress = InetAddress.getByName("localhost");
      byte[] sendData = new byte[1024];
      byte[] receiveData = new byte[1024];
      String sentence = inFromUser.readLine();
      sendData = sentence.getBytes();
      DatagramPacket sendPacket = new DatagramPacket(sendData, sendData.length, IPAddress, 9876);
      clientSocket.send(sendPacket);
      DatagramPacket receivePacket = new DatagramPacket(receiveData, receiveData.length);
      clientSocket.receive(receivePacket);
      String modifiedSentence = new String(receivePacket.getData());
      System.out.println("FROM SERVER:" + modifiedSentence);
      clientSocket.close();
   }
}
```

4. UDP server
```java
import java.io.*;
import java.net.*;

class UDPServer
{
   public static void main(String args[]) throws Exception
      {
         DatagramSocket serverSocket = new DatagramSocket(9876);
            byte[] receiveData = new byte[1024];
            byte[] sendData = new byte[1024];
            while(true)
               {
                  DatagramPacket receivePacket = new DatagramPacket(receiveData, receiveData.length);
                  serverSocket.receive(receivePacket);
                  String sentence = new String( receivePacket.getData());
                  System.out.println("RECEIVED: " + sentence);
                  InetAddress IPAddress = receivePacket.getAddress();
                  int port = receivePacket.getPort();
                  String capitalizedSentence = sentence.toUpperCase();
                  sendData = capitalizedSentence.getBytes();
                  DatagramPacket sendPacket =
                  new DatagramPacket(sendData, sendData.length, IPAddress, port);
                  serverSocket.send(sendPacket);
               }
      }
}
```
