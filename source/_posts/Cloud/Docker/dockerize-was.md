---
title: Dockerization of WAS
category:
  - Docker
tag:
  - Docker
abbrlink: b0c5
date: 2019-08-05 14:22:17
---

## 1. Dockerization of Websphere Liberty Server
### 1.1 Prerequisites
1. Install Eclipse IDE for Enterprise Java Developers [here](https://www.eclipse.org/downloads/packages/)
2. Download WebSphere Liberty Beta runtime [here](https://developer.ibm.com/wasdev/downloads/#asset/runtimes-wlp-beta). Click **Download** button on the webpage and unzip to your preferred directory, such as **/opt/wlp**
3. Install IBM Liberty Developer Tools for Eclipse:
    * Open Eclipse and click **Help** > **Eclipse Marketplace**.
    * In the **Find** field, type **WebSphere**.
    * Locate **IBM Liberty Developer Tools** and then click **Install**. Install **all** items on selection page and restart Eclipse.
    ![IBM Liberty Developer Tools](/images/Docker/DB2-and-WAS/1.png)
    
    ![All Installation Items](/images/Docker/DB2-and-WAS/2.png)

### 1.2 Create a Docker container running Liberty
Open a terminal and type **docker run -e LICENSE=accept -p 8001:9080 -p 8002:9443 --name=wlp -td websphere-liberty** to create a Docker container called wlp which runs WebSphere Liberty (Make sure you already logged in your Docker ID. 8001 and 8002 can be replaced with any available ports on your host). It will automatically download **websphere-liberty** image if you don't have one.

### 1.3 Create a representation of the server in WDT
1. Right-click in the Servers view and select **New** > **Server**
![Add New Server](/images/Docker/DB2-and-WAS/3.png)

2. Under **IBM** select **WebSphere Application Server Liberty** for the server type. Make sure the **Server’s host name** is set to **localhost** and click **Configure runtime environments...**
![Define a New Server](/images/Docker/DB2-and-WAS/4.png)

3. Add or edit **Liberty Runtime Environment** and specify the path to your Liberty runtime installation you downloaded before (Step 4.1.2), then click **Finish**.

![Configure Runtime Environment](/images/Docker/DB2-and-WAS/5.png)
4. After setting up the runtime environments, click **Next**.
5. Select **Server in a Docker container** for the Server type. Select the container (we named our container **wlp**) and fill in a user name and password (a user registry will be automatically created for you using this name and password). Also specify the secure port. The **websphere-liberty** image uses 9443 for the secure port by default.
![Connect to Docker](/images/Docker/DB2-and-WAS/6.png)

6. Click the **Verify** button. When the dialog pops up asking if you want to create a user registry for the user name and password you specified, click **Create**
![Create User Registry](/images/Docker/DB2-and-WAS/7.png)

7. Accept any untrusted security certificate dialogs, then click **Finish**.



## 2. Dockerization of WebSphere Application Server
The IBM WebSphere Application Server docker image is [here](https://hub.docker.com/r/ibmcom/websphere-traditional)

### 2.1 Run websphere-traditional container in docker
Open a terminal and type **docker run --name was -h was -v myvol:/opt/IBM/WebSphere/AppServer -p 9043:9043 -p 9443:9443 -p 8000:8000 -d ibmcom/websphere-traditional:9.0.0.9-profile** to create a Docker container called **was** which runs WebSphere Application Server full profile (Make sure you already logged in your Docker ID. port **8000** can be replaced with any available ports on your host for debugging service. You can switch the WDT to different version (In this case we use **9.0.0.9-profile**), and use another volume name to mount (In this case we use **myvol**). It will automatically download **websphere-traditional** image if you don't have one. The generated password can be retrieved from the container using the following command: **docker exec was cat /tmp/PASSWORD**.

### 2.2 Set up Debugging Service
1. Login to the [admin console](https://localhost:9043/ibm/console/login.do?action=secure) using username (**wsadmin** as default) and password (Use the command above)
1. Navigate to the application server's Debugging Service:
    Servers > Server Types > WebSphere application servers > [serverName] > Debugging Service
2. Check the **Enable service at server startup** checkbox
3. Add/modify the **JVM debug port** if necessary (The port we use is 8000)
4. Add/modify the **JVM debug arguments** if necessary (this may already appear by default): **-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=8000**
5. Apply the changes, Save the new configuration, and Restart the application server

Then, from the Eclipse IDE:
1. Open the **Debug** dialog (e.g. Run > Debug Configurations...)
2. Right-click **Remote Java Application** and select **New**
3. Configure the Remote Java Application:
    1. Name the debug configuration
    2. Browse to select the project to debug (optional)
    3. Use the **Standard (Socket Attach)** Connection Type
    4. Specify the hostname of your WAS server (In this case we use **localhost**)
    5. Specify the port number that was set in the WAS debug options (In this case we use **8000**)
4. Click Apply
5. Click Debug

### 2.3 Network Issue
If failed to connect to remote VM, here are some of the reason:
1. Incorrect host and port combination
2. Close firewall on host
3. Didn't expose debugging service port on running container
