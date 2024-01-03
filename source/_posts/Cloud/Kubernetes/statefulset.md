---
title: StatefulSet
abbrlink: c933
date: 2019-11-07 13:43:55
category:
  - K8s
tag:
  - K8s
keywords:
description:
---

## 1. Replicate Stateful Pods
ReplicaSet可创建并管理多个Pod, 但所有Pod都共享同一PersistentVolumeClaim, 并与同一PersistentVolume绑定, 这种设计模式无法实现分布式数据存储:
![All pods from the same ReplicaSet always use the same PersistentVolumeClaim and PersistentVolume](/images/Kubernetes/statefulset-1.png)

### 1.1 Run Multiple Replicas with Separate Storage
为了让每个Pod使用各自的volume, 可采取以下方式:
1. Create Pods Manually
手动创建多个Pod并使用不同的PersistentVolumeClaim. 由于没有使用ReplicaSet, 所以需要手动管理Pod: Pod或Pod所在的worker node不可用时需手动删除或重建Pod.
2. Use One ReplicaSet per Pod Instance
创造多个ReplicaSet, 每个ReplicaSet管理一个Pod并使用不同的PersistentVolumeClaim. 虽然不用监控Pod状态, 但无法随意修改Pod数量: 当修改Pod数量时, 需手动创建新的ReplicaSet或删除已有ReplicaSet:
![Using one ReplicaSet for each pod instance](/images/Kubernetes/statefulset-2.png)
3. Use Multiple Directories in the Same Volume
使用单个ReplicaSet管理多个Pod, 但每个Pod绑定Volume中不同的文件目录, 从而实现分布式数据. 此方法存在一个缺陷: 由于Pod无法指定Volume的某个文件目录, Pod会自动绑定某个未被使用的目录, 这需要Pod之间的合作:
![Working around the shared storage problem by having the app in each pod use a different file directory](/images/Kubernetes/statefulset-3.png)

### 1.2 Provide a Stable Identity for Each Pod
ReplicaSet适合管理non-stateful application(所有Pod采用相同配置, 使用同一个Volume数据); 对于stateful application, 由于每个Pod拥有不同数据, 因此其他服务需要与cluster中的某个Pod通信, 这就需要Pod拥有不同且稳定的接口: 对于ReplicaSet所管理的Pod集群, 虽然每个Pod有hostname, 但当Pod被reschedule时, hostname会重新分配; 对于指向ReplicaSet的Service, 其他服务访问Service时会被随机分配到某个Pod, 也无法提供一个稳定的Pod接口. 
过时的解决方案: 因为Service拥有稳定的地址, 所以为每个ReplicaSet的Pod分配一个Service; 但操作复杂, 增加Pod时需要为新建的Pod手动绑定Service:
![Using one Service and ReplicaSet per pod to provide a stable network address](/images/Kubernetes/statefulset-4.png)



## 2. StatefulSet
StatefulSet作为Kubernetes的一种Resource, 提供了一种全方面的解决方案来管理stateful application. StatefulSet和ReplicaSet或ReplicationController主要有以下几点不同:
1. Goals: ReplicaSet目的在于管理non-stateful application; StatefulSet负责管理stateful application. 
2. Identity: ReplicaSet在reschedule时会更改Pod名字和hostname; StatefulSet在reschedule时保留Pod名字和hostname
3. Volume: 一个ReplicaSet只能绑定一个Volume; StatefulSet可绑定多个Volume

### 2.1 Provide a Stable Network Identity
StatefulSet中所有Pod的名字都会以递增整数作为结尾(以0为起点), 因此Pod域名变得容易访问; ReplicaSet则随机生成Pod名字:
![Pods created by a StatefulSet have predictable hostnames](/images/Kubernetes/statefulset-5.png)

为StatefulSet创建Headless Service后, 其他服务可通过该Service获取每个Pod的DNS entry. 以**A-0** Pod为例, 访问**a-0.foo.default.svc.cluster.local**即可与该Pod通信. 也可通过SRV record获取pod的名字.
当Pod所在的worker node不可用时, Stateful会在其他worker node上创建该Pod, 且保持该Pod的名字和hostname不变; ReplicaSet则会重新分配Pod的名字和hostname:
![StatefulSet replaces a lost pod with a new one with the same identity](/images/Kubernetes/statefulset-6.png)

当减小StatefulSet的replica count时, 会按照Pod的名字倒序移除Pod, 一次只能移除一个Pod, 序号最大的先被移除; ReplicaSet则会随机移除一个Pod:
![Scaling down a StatefulSet always removes the pod with the highest ordinal index first](/images/Kubernetes/statefulset-7.png)

### 2.2 Provide Stable Dedicated Storage
由于reschedule时必须保证新建的Pod依然绑定原版的Volume, StatefulSet需要维持Pod与PersistentVolumeClaim之间的对应关系, PVC不再需要用户管理:
![A StatefulSet creates both pods and PersistentVolumeClaims](/images/Kubernetes/statefulset-8.png)

由Replica count缩小导致的Pod被移除不会删除对应的PersistentVolumeClaim, 因为一旦PVC被删除, 绑定的PV也会被回收. 为了防止数据丢失, 必须保留PVC的存在. 如果需要回收PV, 可手动删除PVC. 而当replica count恢复到之前数量后, 新建的Pod会自动绑定到之前的PVC:
![StatefulSets preserve the PersistentVolumeClaims when scaling down](/images/Kubernetes/statefulset-9.png)

### 2.3 StatefulSet's At-Most-One Semantics
由于StatefulSet支持新建Pod重用之前Pod的identity(名字, hostname和绑定的PV), 因此必须保证创建Pod时不存在同名Pod. 这就导致StatefulSet对worker node不可用时采用的策略与ReplicaSet不同.



## 3. Use a StatefulSet
### 3.1 Create the App and Container image
为展示StatefulSet的特性, 需要创建一个app可写入和读取Volume数据, 并与其他服务通信:
```js
...
const dataFile = "/var/data/kubia.txt";
...
var handler = function(request, response) {
  if (request.method == 'POST') {
    var file = fs.createWriteStream(dataFile);
    file.on('open', function (fd) {
      request.pipe(file);
      console.log("New data has been received and stored.");
      response.writeHead(200);
      response.end("Data stored on pod " + os.hostname() + "\n");
    });
  } else {
    var data = fileExists(dataFile)
      ? fs.readFileSync(dataFile, 'utf8')
      : "No data posted yet";
    response.writeHead(200);
    response.write("You've hit " + os.hostname() + "\n");
    response.end("Data stored on this pod: " + data + "\n");
  }
};
var www = http.createServer(handler);
www.listen(8080);
```
上述NodeJS App会监听8080端口, 当收到POST请求时, 将请求数据写入**kubia.txt**; 当收到GET请求时, 从**kubia.txt**中读取数据并回复.

### 3.2 Deploy the App through a StatefulSet
为使用StatefulSet部署Application, 需要以下三种resource: PersistentVolume, Service和StatefulSet. StatefulSet会自动创建PersistentVolumeClaim, 所以并不需手动创建PVC. 以下步骤在GCP中运行:

#### 3.2.1 Create the Persistent Volume
创建三个GCE Persistent Disk:
```sh
$ gcloud compute disks create --size=1GiB --zone=us-east1-b pv-a
$ gcloud compute disks create --size=1GiB --zone=us-east1-b pv-b
$ gcloud compute disks create --size=1GiB --zone=us-east1-b pv-c
```
创建三个PV使用GCE Persistent Disk:
```yaml
kind: List
apiVersion: v1
items:
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv-a
  spec:
    capacity:
      storage: 1Mi
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Recycle
    gcePersistentDisk:
      pdName: pv-a
      fsType: nfs4
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv-b
  ...
```

#### 3.2.2 Create the Governing Service
创建Headless Service为stateful Pods提供network identity:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia
spec:
  clusterIP: None
  selector:
    app: kubia
  ports:
  - name: http
    port: 80
```

#### 3.2.3 Create the StatefulSet Manifest
除了**volumeClaimTemplates**外, 其他配置与ReplicaSet相同. **volumeClaimTemplates**指定StatefulSet创建何种规格的PVC. 
```yaml
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: kubia
spec:
  serviceName: kubia
  replicas: 2
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
      - name: kubia
        image: luksa/kubia-pet
        ports:
        - name: http
          containerPort: 8080
        volumeMounts:
        - name: data
          mountPath: /var/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      resources:
        requests:
          storage: 1Mi
      accessModes:
      - ReadWriteOnce
```

#### 3.2.4 Create the StatefulSet
调用**kubectl apply**可使用YAML文件创建StatefulSet:
```sh
$ kubectl create -f kubia-statefulset.yaml
statefulset "kubia" created

$ kubectl get pods
NAME    READY STATUS            RESTARTS AGE
kubia-0 0/1   ContainerCreating 0        1s
```
由于StatefulSet会在完成第一个Pod启动后再启动第二个, 所以一开始会显示第一个Pod的状态:
```sh
$ kubectl get pods
NAME    READY STATUS            RESTARTS AGE
kubia-0 1/1   Running           0        8s
kubia-1 0/1   ContainerCreating 0        2s
```

#### 3.2.5 Examine the Generated Stateful Pod
```yaml
$ kubectl get po kubia-0 -o yaml
apiVersion: v1
kind: Pod
metadata:
  ...
spec:
  containers:
  - image: luksa/kubia-pet
  ...
    volumeMounts:
    - mountPath: /var/data
      name: data
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-r2m41
      readOnly: true
  ...
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-kubia-0
  ...
```
可以看到, StatefulSet会为kubia-0自动创造一个名为**data-kubia-0**的PVC, 并与container绑定:
```sh
$ kubectl get pvc
NAME         STATUS VOLUME CAPACITY ACCESSMODES AGE
data-kubia-0 Bound  pv-c   0                    37s
data-kubia-1 Bound  pv-a   0                    37s
```

### 3.3 Communicate with Your Pods
由于StatefulSet使用的是Headless Service, 因此只能直接与Pod通信, 而不能通过Service通信. 为实现与特定Pod通信, 可向API server发送HTTP请求, 将其作为proxy, 访问路径如下:
```text
<apiServerHost>:<port>/api/v1/namespaces/default/pods/kubia-0/proxy/<path>
```
为保证避免配置SSL certificate, 可使用**kubectl proxy**来生成proxy与API server通信:
```sh
$ kubectl proxy
Starting to serve on 127.0.0.1:8001

$ curl localhost:8001/api/v1/namespaces/default/pods/kubia-0/proxy/
You've hit kubia-0
Data stored on this pod: No data posted yet
```
GTE请求的通信流程如下:
![Connect to a pod through both the kubectl proxy and API server proxy](/images/Kubernetes/statefulset-10.png)

也可以向Pod发送POST请求:
```sh
$ curl -X POST -d "Hey there!" localhost:8001/api/v1/namespaces/default/pods/kubia-0/proxy/
Data stored on pod kubia-0

$ curl localhost:8001/api/v1/namespaces/default/pods/kubia-0/proxy/
You've hit kubia-0
Data stored on this pod: Hey there!
```

删除Pod后, StatefulSet会像ReplicaSet一样重建新的Pod, 并使用之前的名字, hostname和Volume:
![A stateful pod may be rescheduled to a different node, but it retains the name, hostname, and storage](/images/Kubernetes/statefulset-11.png)

当减小replica count时, StatefulSet会从序号最大Pod开始关闭运行, 同一时间只会有一个Pod处于terminating状态.



## 4. Discover peers in a StatefulSet
StatefulSet必须保证cluster中的每个成员都可以访问到其管理的Pod, 虽然通过API server可以实现与Pod直连, 但client端需要设置好配置才能连接至API server. 为此可使用SRV records解决该问题. 
SRC records可指明某个特定service下的hostname和port. 首先运行**tutum/dnsutils**来允许用户在container中执行**dig**和**nslookup**命令:
```sh
$ kubectl run -it srvlookup --image=tutum/dnsutils --rm \
  --restart=Never -- dig SRV kubia.default.svc.cluster.local


$ dig SRV kubia.default.svc.cluster.local
...
;; ANSWER SECTION:
kubia.default.svc.cluster.local. 30 IN SRV 10 33 0 kubia-0.kubia.default.svc.cluster.local.
kubia.default.svc.cluster.local. 30 IN SRV 10 33 0 kubia-1.kubia.default.svc.cluster.local.
;; ADDITIONAL SECTION:
kubia-0.kubia.default.svc.cluster.local. 30 IN A 172.17.0.4
kubia-1.kubia.default.svc.cluster.local. 30 IN A 172.17.0.6
...
```
可以看到, SRV record中kubia-0和kubia-1都指向headless service. 在程序中执行**SRV DNS lookup**可获取该service下所有Pod的hostname:
```js
dns.resolveSrv("kubia.default.svc.cluster.local", callBackFunction);
```

### 4.1 Implement peer discovery through DNS
```js
...
const dns = require('dns');
const dataFile = "/var/data/kubia.txt";
const serviceName = "kubia.default.svc.cluster.local";
const port = 8080;
...
var handler = function(request, response) {
  if (request.method == 'POST') {
  ...
  } else {
    response.writeHead(200);
    if (request.url == '/data') {
      var data = fileExists(dataFile)
        ? fs.readFileSync(dataFile, 'utf8')
        : "No data posted yet";
      response.end(data);
    } else {
      response.write("You've hit " + os.hostname() + "\n");
      response.write("Data stored in the cluster:\n");
      dns.resolveSrv(serviceName, function (err, addresses) {
        if (err) {
          response.end("Could not look up DNS SRV records: " + err);
          return;
        }
        var numResponses = 0;
        if (addresses.length == 0) {
          response.end("No peers discovered.");
        } else {
          addresses.forEach(function (item) {
            var requestOptions = {
              host: item.name,
              port: port,
              path: '/data'
            };
            httpGet(requestOptions, function (returnedData) {
              numResponses++;
              response.write("- " + item.name + ": " + returnedData);
              response.write("\n");
              if (numResponses == addresses.length) {
                response.end();
              }
            });
          });
        }
      });
    }
  }
};
...
```
经过上述修改后, StatefulSet中的任何一个Po收到GET请求都会想通过SRV lookup获取所有Pod hostname, 再向所有Pod hostname的**/data**发送GET请求来获取数据, 流程如下:
![The operation of your simplistic distributed data store](/images/Kubernetes/statefulset-12.png)

### 4.2 Update a StatefulSet
当StatefulSet的YAML文件被修改后, 原先创建的Pod不会有任何更新, 只有新建的Pod会采用新的manifest. 如果想更新之前的Pod, 只能删除并重建:
```sh
$ kubectl edit statefulset kubia
```
用editor打开StatefulSet definition, 将spec-relicas从2改为3, 并将spec.template.spec.containers.image从**luksa/kubiapet**改为**luksa/kubia-pet-peers**, 保存并退出文件:
```sh
$ kubectl get pods
NAME    READY STATUS            RESTARTS AGE
kubia-0 1/1   Running           0        25m
kubia-1 1/1   Running           0        26m
kubia-2 0/1   ContainerCreating 0        4s
```
**kubia-0**和**kubia-1**没有任何更新, **kubia-2**则采用新的image.



## 5. Understand How StatefulSets Deal with Node Failures
当某个worker node不可用时, Kubernetes无法获知其中Pod的运行状况. 由于StatefulSet需要保证同一时间不能存在两个相同的Pod运行, 只有确定Pod不可运行时才会创建新的Pod. 

### 5.1 Simulate a Node's Disconnection From the Network
假设StatefulSet运行在GCP上, 管理3个Pod: **kubia-0**, **kubia-1**和**kubia-2**, 分别运行在不同的worker node上. 为测试StatefulSet针对worker node不可用时的应对策略, 需要先断开一个worker node的网络接口:
```sh
$ gcloud compute ssh gke-kubia-m0g1
$ sudo ifconfig eth0 down
```
查看worker nodes状态. 由于**gke-kubia-m0g1**的Kubelet无法连接至Kubernetes API server, 一段时间后该worker node将被标记为**NotReady**:
```sh
$ kubectl get node
NAME           STATUS   AGE VERSION
gke-kubia-596v Ready    16m v1.6.2
gke-kubia-m0g1 NotReady 16m v1.6.2
gke-kubia-sgl7 Ready    16m v1.6.2
```
查看pods状态. 由于control plane无法获取worker node上Pod的状态更新, 所以Pod状态被修改为**Unknown**:
```sh
$ kubectl get pods
NAME    READY STATUS  RESTARTS AGE
kubia-0 1/1   Unknown 0        15m
kubia-1 1/1   Running 0        14m
kubia-2 1/1   Running 0        13m
```
如果worker node重新上线, 则Pod回归**Running**状态. Kubernetes 1.5或更高版本后, 如果Pod一直维持**Unknown**状态超过一定时间, Kubernetes control plane会试图将Pod移除, 将Pod状态改为**Terminating**; 但由于worker node断开连接, kubelet无法回应master的删除请求, 所以Pod会一直处于**Terminating**. 只有以下三种情况下, Kubernetes会从API server上删除Pod的信息:
1. 删除worker node
2. worker node重新连接, kubelet响应了删除Pod的请求
3. 强制删除Pod

### 5.2 Delete the Pod Forcibly
强制删除不会等待kubelet的确认. 无论Pod是否被终止, API server上的Pod信息都会被删除, StatefulSet也会创建新的Pod来替代被删除的Pod:
```sh
$ kubectl delete pod kubia-0 --grace-period=0 --force
pod "kubia-0" deleted

$ kubectl get pods
NAME READY STATUS RESTARTS AGE
kubia-0 0/1 ContainerCreating 0 8s
kubia-1 1/1 Running 0 20m
kubia-2 1/1 Running 0 19m
```
强制删除可能违背StatefulSet的At-Most-One原则, 必须保证worker node不再上线时才能强制删除Pod; 若worker node重新上线, 两个同名Pod可能会导致数据丢失.