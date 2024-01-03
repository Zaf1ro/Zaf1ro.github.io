---
title: Services
category:
  - K8s
tag:
  - K8s
abbrlink: '1936'
date: 2019-10-21 08:34:21
keywords:
description:
---

## 1. Introduction
Kubernetes不支持配置单个Pod的IP address或hostname, 因为这样做有几个缺陷:
1. Pod生存周期短暂. Pod的数量随时可能增加或减少, 且所处的worker node随时改变
2. Pod被确定到某个worker node后才能获得一个明确的IP address, 因此client无法提前得知pod的IP address
3. Horizontal scaling提供了多个Pod来实现相同服务, 因此同服务类型的Pod应共享一个IP address

为解决这些问题, Kubernetes提供了Service作为一个resource为一组Pod提供入口. Service会提供了一个不变的IP address和Port: 当client想要连接该组Pod时, 可直接访问其Service的IP address和Port; client也不必在乎Pod处于哪个worker node之中, 或cluster中有几个Pod.
假设现在有frontend web server和backend web server: frontend web server有多个Pod实现horizontal scaling; backend web server则只有一个Pod. 因此client需要通过service连接frontend web server中的一个pod, frontend web server的pod再通过另一个service连接backend web server的Pod.
![Both internal and external clients usually connect to pods through services](/images/Kubernetes/svc-1.png)

### 1.1 Create Services
Service使用label selector来选择Pod. 以下是两种创建service的方式:
1. 调用**kubectl expose** command来创建service
2. 创建YAML文件并调用**kubectl create**创建service, port指service暴露的端口, targetPort指Pod暴露的端口. 例如:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: kubia 
```

调用**kubectl get svc**可查看当前cluster上的所有service:
```sh
$ kubectl get svc
NAME       CLUSTER-IP     EXTERNAL-IP PORT(S) AGE
kubernetes 10.111.240.1   <none>      443/TCP 30d
kubia      10.111.249.153 <none>      80/TCP  6m 
```
注意: service中的cluster IP只是虚拟地址, 只有cluster内的Pod才能访问该IP address. 以下是在cluster内部测试service的几种方法:
1. 创建新的Pod并向cluster IP发送请求, 查看是否得到回复
2. 通过ssh进入cluster中的worker node, 调用curl command发送请求, 查看是否得到回复
3. 利用现有Pod执行curl command向service发送请求, 查看是否得到回复

#### 1.1.1 Remotely Execute Commands in Running Containers
**kubectl exec**可实现远程在Pod的container内部执行command. 以下是从名为kubia-7nog1的Pod中执行curl command的例子:
```sh
$ kubectl exec kubia-7nog1 -- curl -s http://10.111.249.153
You’ve hit kubia-gzwli
```
Double dash(- -)作为kubectl的option之一, 可防止kubectl读取命令时将**- -**后的command当做kubectl的参数. 若不使用- -, 则**-s**会被当做kubectl的参数而引发错误. 以下是整个**kubectl exec**的执行流程:
![Using kubectl exec to test out a connection to the service by running curl in one of the pods](/images/Kubernetes/svc-2.png)

#### 1.1.2 Configure Session Affinity on the Service
由于client每次请求时都可能遇到不同的Pod, 因为service会随机挑选一个Pod服务client. 若需要特定client始终连接特定Pod, 则需要设置sessionAffinity属性:
```yaml
apiVersion: v1
kind: Service
spec:
  sessionAffinity: ClientIP
  ...
```
sessionAffinity默认为None. 由于Kubernetes service无法操作TCP/IP的应用层(例如: HTTP), 所以无法通过cookie设置session affinity, 只能通过IP address进行load balance. 当设置为ClientIP后, 即使同一个IP address下有多个client连接, 也只会连接到同一Pod.

#### 1.1.3 Expose Multiple Ports in the Same Service
Kubernetes Service支持多个port. 当使用多个Port时, 必须为每个Port指定名字:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia
  spec:
    ports:
    - name: http
      port: 80
      targetPort: 8080
    - name: https
      port: 443
      targetPort: 8443
    selector:
      app: kubia 
```

#### 1.1.4 Use Named Ports
Service YAML文件中的targetPort也可以用端口名来代替一个确定的端口号: 首先需要Pod暴露其port number和对应的port name:
```yaml
kind: Pod
spec:
  containers:
  - name: kubia
    ports:
    - name: http
      containerPort: 8080
    - name: https
      containerPort: 8443 
```
之后就可以在Service用port name替代port number, 这样即便Pod修改其port number, Service也不需要做任何修改:
```yaml
apiVersion: v1
kind: Service
spec:
  ports:
  - name: http
    port: 80
    targetPort: http
  - name: https
    port: 443
    targetPort: https
```

### 1.2 Discover Services
虽然Service提供了一个稳定的IP address和多个Port允许client随时与Pod通信, 但client如何获知Service的IP address和Port? Kubernetes提供了多种方式方便client获知并连接至Service.

#### 1.2.1 Discover Services through Environment Variables
当Pod被启动时, Kubernetes会为其初始化environment variables, 其中就包括其service所指向的IP address和Port. 但必须保证Service在Pod之前被创建, 否则无法通过environment variables查看. 
```sh
$ kubectl exec kubia-3inly env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=kubia-3inly
KUBERNETES_SERVICE_HOST=10.111.240.1
KUBERNETES_SERVICE_PORT=443
...
KUBIA_SERVICE_HOST=10.111.249.153
KUBIA_SERVICE_PORT=80
...
```

#### 1.2.2 Discover Services through DNS
在Kubernetes的kube-system namespace下有一个Pod叫做kube-dns, 它可作为一个DNS server负责将FQDN(fully qualified domain name, 也就是Service的域名)转换为Service IP address. 每个Service在DNS server内部都有一个DNS entry.
以backend database service为例, 其FQDN为:
```sh
backend-database.default.svc.cluster.locals
```
backend-database为Service的名字, default表示Service所处的namespace, svc.cluster.local则是cluster domain的后缀, 每个cluster local service共享该后缀, 因此也可以不写这个后缀. 若frontend web server的Pod与backend database同一namespace, 则可以省略**default**, FQDN直接写**backend-database**即可.

#### 1.2.3 Run a Shell in a Pod's Container
直接进入Pod后查看**/etc/resolv.conf**也可以看到FQDN
```sh
root@kubia-3inly:/# cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local ...
```



## 2. Connect to Services Living Outside the Cluster
第一节只针对cluster内的Pod通信, 以下提到的是cluster内的Pod向cluster外的service发送信息.

### 2.1 Endpoints
Kubernetes中, Service并不会直接与Pod相连, 而是与Endpoint连接. Endpoint作为Kubernetes中的一种resource, 其包含一个或多个IP address/Port number, 负责将Pod和Service连接起来. 当调用**kubectl describe svc ...**时可看到Service拥有的Endpoints:
```sh
$ kubectl describe svc kubia
Name: kubia
Namespace: default
Labels: <none>
Selector: app=kubia
Type: ClusterIP
IP: 10.111.249.153
Port: <unset> 80/TCP
Endpoints: 10.108.1.4:8080,10.108.2.5:8080,10.108.2.6:8080
Session Affinity: None
```
也可调用**kubectl get endpoints ...**直接读取Service拥有的Endpoints:
```sh
$ kubectl get endpoints kubia
NAME  ENDPOINTS                                       AGE
kubia 10.108.1.4:8080,10.108.2.5:8080,10.108.2.6:8080 1h
```

### 2.2 Manually Configure Service Endpoints
一旦Service指定label selector, Kubernetes会自动找到符合label的Pod并创建相对应的Endpoints. 因此, 若需手动创建Endpoint, 应避免在Service中使用label selector, 如下:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-service
spec:
  ports:
  - port: 80 
```
Endpoints的创建方式与其他resource相同, 创建YAML文件即可. Endpoint必须与某个Service同名, 并在subsets中指定cluster外部的service IP address/Port.
```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: external-service
subsets:
  - addresses:
  - ip: 11.11.11.11
  - ip: 22.22.22.22
  ports:
  - port: 80 
```
创建Service和Endpoints完毕后, 这之后创建的Pod中environment variables都含有该Service的IP address/Port.
![Pods consuming a service with two external endpoints](/images/Kubernetes/svc-3.png)

### 2.3 Create an Alias for an External Service
Service的spec.type默认为ClusterIP, 表示Service只能由cluster内部的Pod访问, 因此需要创建Endpoint将内部访问映射到外部IP address. 若将Service的spec.type设置为ExternalName, Kubernetes会将Service映射到cluster外部的域名上, 从而实现cluster外部的访问功能.
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-service
spec:
  type: ExternalName
  externalName: someapi.somecompany.com
  ports:
  - port: 80
```
Kubernetes会为ExternalName类型的Service创建一个CNAME DNS record. 当cluster内的Pod访问external-service.default.svc.cluster.local时, 请求会被转移到someapi.somecompany.com, 因此Service也不需要cluster IP.



## 3. Expose Services to External Clients
第一节和第二节只针对cluster内的Pod向cluster内或cluster外发送请求. 本节则着重于cluster外部向cluster内的Pod发送请求. 例如: 为frontend web server创建Service, 从而让cluster外的client可以访问到.
![Exposing a service to external clients](/images/Kubernetes/svc-4.png)

### 3.1 NodePort
当使用NodePort类型的Service时, Kubernetes会在每个worker node上保留一个Port用于该Service使用. 以下是创建NodePort Service的例子:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-nodeport
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30123
  selector:
    app: kubia
```
NodePort也支持Service创建其cluster IP, 但多一个属性: nodePort. 当cluster外的client访问cluster中任意worker node的nodePort时, 会被Service导向其Pod, 从而实现cluster外的client访问cluster内的Pod. 假设cluster中有两个worker node, cluster中的Service如下:
```sh
$ kubectl get svc kubia-nodeport
NAME           CLUSTER-IP     EXTERNAL-IP PORT(S)      AGE
kubia-nodeport 10.111.254.223 <nodes>     80:30123/TCP 2m
```
共有三种方式访问该Service:
1. 10.11.254.223:80 inside the cluster
2. <1st node’s IP>:30123 outside the cluster
3. <2nd node’s IP>:30123 outside the cluster

![An external client connecting to a NodePort service either through Node 1 or 2](/images/Kubernetes/svc-5.png)

无论cluster外的client向哪个worker node发送请求, 只要经过30123端口, 都会被Service捕获并传送到相应的Pod. 

### 3.2 LoadBalancer
LoadBalancer提供了一个公有IP地址来将所有请求转移到worker node上. 作为NodePort的升级版, cluster外的client不需要知道worker node的地址即可与cluster内的Pod通信. LoadBalancer Service的创建方式如下:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-loadbalancer
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: kubia
```
大部分cloud infrastructure都支持LoadBalancer. 但执行**kubectl create**创建LoadBalancer后, cloud infrastructure会创建load balancer并将其IP address写入Service. 
```sh
$ kubectl get svc kubia-loadbalancer
NAME               CLUSTER-IP     EXTERNAL-IP    PORT(S)      AGE
kubia-loadbalancer 10.111.241.153 130.211.53.173 80:32143/TCP 1m
```
上述例子中, 130.211.53.173即为load balancer的公有IP地址.
![An external client connecting to a LoadBalancer service](/images/Kubernetes/svc-6.png)

### 3.3 The Peculiarities of External Connections
Clsuter外的client通过NodePort Service(包括LoadBalancer)访问Pod时, 会由Service随机挑选一个Pod与client进行通信. Client访问的worker node不一定含有Pod, 因此Service需要额外的一个network hop重定位到拥有Pod的worker node. 若不想进行这额外的一步重定向, 可在Service中设置:
```sh
spec:
  externalTrafficPolicy: Local
```
若client访问的worker node没有Pod, 则请求会被一直挂起, 因此需要保证load balancer总能将请求发向拥有Pod的worker node. 使用externalTrafficPolicy还有另一个缺点: 造成访问Pod的频次失去平衡. 假设cluster中存在两个worker nodes, node A有一个Pod, node B中有两个Pod. 则访问的结果如下:
![A Service using the Local external traffic policy may lead to uneven load distribution across pods](/images/Kubernetes/svc-7.png)

当cluster内的client通过Service访问Pod时, Pod可以得知client的cluster IP地址; 但当cluster外的client访问Pod时, 其源地址经过SNAT(Source Network Address Translation)后已被修改, 因此Pod无法得知client的真实IP地址.



## 4. Expose Services Externally through an Ingress Resource
LoadBalancer虽然解决了Pod的通讯入口问题, 但每次创建一个Service都需要一个公有IP地址, 代价太高. Kubernetes为此提供Ingress, Ingress只需一个公有IP地址, 通过不同的host和path为多个Service提供外部通讯的入口:
![Multiple services can be exposed through a single Ingresss](/images/Kubernetes/svc-8.png)

以下是创建Ingress的YAML示例. 所有**kubia.example.com**的请求都会被重定向到**kubia-nodeport** service的80端口
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubia
spec:
  rules:
  - host: kubia.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kubia-nodeport
          servicePort: 80
```

### 4.1 Access the Service through the Ingress
如需查看Ingress的IP:
```sh
$ kubectl get ingresses
NAME  HOSTS             ADDRESS        PORTS AGE
kubia kubia.example.com 192.168.99.100 80    29m
```
得知Ingress的IP地址后, 即可配置DNS server将设置的域名解析到该IP地址. 当cluster外的client向该域名发送请求时, 请求首先会经过DNS解析转发至Ingress的IP地址, Ingress Controller再通过判断Host header并发送至某个Service, 被选中的Service通过Endpoints找到可用的Pod.
![Access pods through an Ingress](/images/Kubernetes/svc-9.png)

### 4.2 Expose Multiple Services through the Same Ingress
Ingress的两个属性让单个IP地址指向不同的Services: rules和paths. 
1. paths可指定同一个host下的不同path
```yaml
...
  - host: kubia.example.com
    http:
      paths:
      - path: /kubia
        backend:
          serviceName: kubia
          servicePort: 80
      - path: /foo
        backend:
          serviceName: bar
          servicePort: 80
```
2. rules可指向不同的host
```yaml
...
  spec:
    rules:
    - host: foo.example.com
      http:
        paths:
        - path: /
          backend:
            serviceName: foo
            servicePort: 80
    - host: bar.example.com
      http:
        paths:
        - path: /
          backend:
            serviceName: bar
            servicePort: 80
```

### 4.2 Configure Ingress to handle TLS Traffic
当client向Ingress Controller创建TLS连接时, Ingress Controller会终止TLS连接, 因为client与controller之间是加密的, 但controller与Pod却不是. 因此需要在controller中加入certificate和private key, Pod中的进程不必支持TLS. Certificate和private key都需要放在Kubernetes中的一种resource中: Secret. 
1. 创建private key和certificate:
```sh
$ openssl genrsa -out tls.key 2048
$ openssl req -new -x509 -key tls.key -out tls.cert -days 360 
-subj /CN=kubia.example.com
```
2. 创建Secret. 本例中Secret名为**tls-secret**
```sh
$ kubectl create secret tls tls-secret --cert=tls.cert --key=tls.key
secret "tls-secret" created
```
3. 在Ingress中加入Secret
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubia
spec:
  tls:
  - hosts:
    - kubia.example.com
    secretName: tls-secret
  rules:
  - host: kubia.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kubia-nodeport
          servicePort: 80
```



## 5. Signal when a Pod is Ready to Accept Connections
当某个Pod被创建时, 若其带有Service选中的label, 则其会被直接纳入到Service的管理中. 此时Pod可能未启动完毕, 若收到client请求, 则可能发生不确定的异常情况. Kubernetes提出readiness probe来帮助Service判断Pod是否可以处理请求, readiness probe会定期检查Pod, 但并不负责终止或重启container. 
与liveness probe相同, readiness probe也有三种类型:
* An Exec probe: 在container中执行command并检查exit status code是否为0
* An HTTP GET probe: 向container发送HTTP GET请求并检查HTTP status code
* A TCP Socket probe: 向container的特定端口创建TCP connection并检查connection是否创建成功

假设Service有3个Pod, 其中一个Pod的readiness probe探测到container没有正常运行, 则Service不会将client的请求转发给该Pod.
![A pod whose readiness probe fails is removed as an endpoint of a service](/images/Kubernetes/svc-10.png)

### 5.1 Add a Readiness Probe to a Pod
```yaml
apiVersion: v1
kind: ReplicationController
...
spec:
  ...
  template:
    ...
    spec:
      containers:
      - name: kubia
        image: luksa/kubia
        readinessProbe:
          exec:
            command:
            - ls
            - /var/ready
        ...
```
上述YAML文件中为container指定一个readiness probe. 该readiness probe会在Pod被创建后执行**ls /var/ready**. 若**/var/ready**不存在, 则Pod不会接收到任何请求; 若**/var/ready**存在, 则该Pod的状态会被切换为Ready.
```sh
$ kubectl get pods
NAME        READY STATUS  RESTARTS AGE
kubia-53thy 0/1   Running 0        1m
```
除此之外, readiness probe和liveness probe一样具有其他属性值: initialDelaySeconds, timeoutSeconds, periodSeconds

### 5.2 What Readiness Probe Should Do
1. 为保证client的请求总会成功, 一定要在Pod中加入readiness probe来不断探测container是否能够接受请求; 否则client可能会连接到正在启动或不可用的Pod.
2. 当Pod被关闭时, 一旦Pod收到termination signal, Service就会将该Pod从列表中除名, 所以不需要readiness probe做任何退出操作.



## 6. Headless Service
Service使得cluster内外的client可轻松地与Service管辖的Pod通信, 但Service只能随机选取一个Pod通信, 且Service内部无法让一个Pod与另一个特定的Pod互相通信. 因为Service只生成一个Cluster IP来表示所有Pods, 无法为每个Pod生成一个单独的IP. 为此, Kubernetes允许为Pod提供DNS lookup: 创建Service时, 将clusterIP设置为None, DNS server会直接返回Service管辖内所有Pod的IP, 而不是cluster IP. Pod可利用这些信息来连接另一个Pod.

### 6.1 Create a Headless Service
创建一个clusterIP为None的Service:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-headless
spec:
  clusterIP: None
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: kubia
```

### 6.2 Discover Pods through DNS
由于当前Service管辖的Pod没有DNS lookup功能, 所以需要新建一个Pod来提供DNS lookup:
```sh
$ kubectl run dnsutils --image=tutum/dnsutils
--generator=run-pod/v1 --command -- sleep infinity
pod "dnsutils" created
```
接下来就可以利用新的Pod查看Service内Pod的IP和域名
```sh
$ kubectl exec dnsutils nslookup kubia-headless
...
Name: kubia-headless.default.svc.cluster.local
Address: 10.108.1.4
Name: kubia-headless.default.svc.cluster.local
Address: 10.108.2.5 
```
上述例子中, headless service的FQDN为kubia-headless.default.svc.cluster.local, 该Service共有两个Pod处于Ready状态. 虽然Service依然提供load balance, 但client通过headless service访问特定Pod时并不会经过service proxy.

### 6.3 Discover all pods that aren't ready
若需让Service展示所有管辖内的Pod, 即便Pod没有处于Ready状态, 需在创建Service时使用alpha feature或publishNotReadyAddresses域来标示:
```yaml
kind: Service
metadata:
  ...
  annotations:
    service.alpha.kubernetes.io/tolerate-unready-endpoints: "true"

# ----- or -----

kind: Service
...
spec:
  ...
  publishNotReadyAddresses: true
  ...
```

