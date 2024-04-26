---
title: Dockerization of DB2
category:
  - Docker
tag:
  - Docker
abbrlink: 6df5
date: 2019-07-30 10:10:10
---

## 1. Register for a Docker ID(Skip if already had)
1. Go to the [DockerHub SignUp page](https://hub.docker.com/signup).
2. Enter a username that will become your Docker ID.
3. Enter a unique, valid email address.
4. Enter a password between 6 and 128 characters long.
5. Click **Sign Up**.
6. Docker sends a verification email to the address you provided.
7. Click the link in the email to verify your address.



## 2. Install Docker(Skip if already installed)
### 2.1 System Requirements
1. Windows: 
    * Windows 10 64 bit: Pro, Enterprise or Education (Build 15063 or later).
    * Virtualization is enabled in BIOS.
    * At least 4GB of RAM.
2. Mac OS:
    * Mac hardware must be a 2010 or newer model, macOS Sierra 10.12 and newer macOS releases.
    * At least 4GB of RAM
    * VirtualBox prior to version 4.3.30 must NOT be installed. If you have a newer version of VirtualBox installed, it’s fine.

### 2.2 Installation
1. Windows: 
    1. Download [Desktop for Windows](https://hub.docker.com/editions/community/docker-ce-desktop-windows) using Docker ID.
    2. Double-click Docker Desktop for Windows **Installer.exe** to run the installer.
    3. Follow the install wizard to accept the license, authorize the installer, and proceed with the install.
2. Mac OS:
    1. Download [Docker Desktop for Mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac) using Docker ID.
    2. Double-click **Docker.dmg** to open the installer, then drag Moby the whale to the Applications folder.
    3. Double-click **Docker.app** in the Applications folder to start Docker.



## 3. Dockerization of DB2
### 3.1 Install the DB2 Docker container
1. Open a Terminal(Mac OS) or Command Prompt(Windows).
2. Type **docker login** to log in to a Docker registry
3. Type **docker run  --name db2 --privileged=true -p 50000:50000 -e DB2INST1_PASSWORD=<YOUR_PWD> -e DBNAME=<DB_NAME> -e LICENSE=accept -d ibmcom/db2**. It will automatically download the latest version of DB2 image from docker registry and run a new container named **db2**.
4. You can see all running Docker containers by command **docker ps -as**.
```bash
MacBook:~ username$ docker ps -as
CONTAINER ID        IMAGE           COMMAND                  CREATED             STATUS             PORTS                                                          NAMES        SIZE
67dc058f818f        ibmcom/db2      "/var/db2_setup/lib/…"   26 hours ago        Up 18 minutes      22/tcp, 55000/tcp, 60006-60007/tcp, 0.0.0.0:50000->50000/tcp   db2          7.4MB (virtual 2.97GB)
```
5. Or stop and start DB2: 
```bash
docker stop db2
docker start db2
```

### 3.2 Set up the DB2 Docker container
1. Open a bash terminal inside the DB2 container
```bash
docker exec -i -t db2 /bin/bash
```
2. Switch to the **db2inst1** Linux user which is set up to run DB2
```bash
su - db2inst1
```
3. Then you can run DB2 SQL statements, such as
```bash
db2 create db <DB_NAME>
```

### 3.3 Set up the JDBC Connection
1. Download and install DB2 JDBC Driver [here](http://www-01.ibm.com/support/docview.wss?uid=swg21363866)
2. Set up all connection properties
```java
[
    'jdbc.driver': 'com.ibm.db2.jcc.DB2Driver',
    'jdbc.user'  : 'db2inst1',
    'jdbc.pass'  : '<YOUR_PWD>',
    'jdbc.url'   : 'jdbc:db2://127.0.0.1:50000/<DB_NAME>'
]
```
