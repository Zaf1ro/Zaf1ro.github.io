---
title: Pods
abbrlink: f841
date: 2019-10-10 12:19:20
category:
  - K8s
tag:
  - K8s
keywords:
description:
---

## 1. Introduction
Pod作为k8s中的最小可部署单位, 其中可包含一个或多个container. 但一个pod中的container不可以处于不同nodes中.
![All containers of a pod run on the same node](/images/Kubernetes/pods-1-1.png)

K8s中, Pod, Container和Node的区别如下:
* Container: 表示一个独立的应用程序及其依赖
* Pod: 作为k8s中的一个抽象概念, 表示项目中最小的逻辑单元, 其中可包含一个或多个container, 且每个container拥有不同的功能, 并共同组成一个服务
* Node: 表示一个物理机器或虚拟机

### 1.1 Why we need pods
乍看之下container与pod存在功能重叠, 似乎并没有必要使用pod, 但pod为container做了一层必要的封装:
* container内的进程间通信需要开发者自行维护; pod内的container共享UTC namespace和network namespace, 可通过localhost connection与其他container直接通信
* container内的进程崩溃时, 开发者需要某种机制检测崩溃并重启; k8s提供一整套pod重启机制(restart policy, liveness probe, backoff delay, backoff reset等)来重启pod中崩溃的container
* container内进程的日志需开发者自行维护; k8s可查看pod内所有container的日志, 也可单独查看pod内某个container的日志
* container内进程共享同一文件系统, 容易导致文件操作冲突; pod内的container拥有各自mount namespace, 因此container的文件系统相互隔离

### 1.2 How containers share the same IP and port
一个pod内的所有container共享一个loopback network interface, 因此需避免多个container使用一个port; 不同pod内的container不存在该问题, 因为每个pod拥有各自的network namespace.
一个k8s cluster内的pod可通过以下方式相互通信:
* IP address: 每个pod拥有独立IP address, 可直接向pod对应的IP address发送信息. 即使pod位于不同node, pod的IP address也不会重复.
  ![Each pod gets a routable IP address and all other pods see the pod under that IP address](/images/Kubernetes/pods-1-2.png)
* Service: 表示一组拥有相同功能的pod集群, pod可直接向service发送信息, service会进行负载均衡, 并将消息发送给其中一个pod
* DNS Resolution: k8s提供一个内置的DNS server, pod和service都可拥有自己的hostname, 让通信更轻松

### 1.3 Organize containers across pods properly
K8s允许在单个pod中运行多个container, 但并不提倡这种做法: k8s无法水平拓展container, 同一pod中container的水平拓展会被绑定到一起. 假设pod中包含一个frontend container和一个backend container, 由于大部分情况下后端的压力更大, 需要比前端更多的container, 因此应将frontend container与backend container放置到不同的pod中.
![A container shouldn‘t run multiple processes / A pod shouldn‘t contain multiplecontainers](/images/Kubernetes/pods-1-3.png)

通常一个pod中放置多个container是因为一个主体container需要一个或多个辅助container. 例如, web server需要一个downloader定期从外部下载所需资源, 或者log rotator, data processor, communication adapter.
![A main container and containers that support the main one](/images/Kubernetes/pods-1-4.png)

以下是判断pod中是否放置多个container的标准:
* containers是否可以运行在不同的pod中?
* containers是否呈现为单个组件
* containers是否作为一个整体被scaling


## 2. Create pod from YAML or JSON descriptors
### 2.1 YAML descriptor of an existing pod
执行`kubectl run`可通过YAML或JSON文件创建一个全新的pod. 执行`kubectl get pod ... -o yaml`可获取该pod的YAML文件定义. 
```yaml
$ kubectl get pod kubia-zxzij -o yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubernetes.io/created-by: ...
  creationTimestamp: 2016-03-18T12:37:50Z
  generateName: kubia-
  labels:
    run: kubia
  name: kubia-zxzij
  namespace: default
  resourceVersion: "294"
  selfLink: /api/v1/namespaces/default/pods/kubia-zxzij
  uid: 3a564dc0-ed06-11e5-ba3b-42010af00004
spec:
  containers:
  - image: luksa/kubia
    imagePullPolicy: IfNotPresent
    name: kubia
    ports:
    - containerPort: 8080
      protocol: TCP
    resources:
      requests:
        cpu: 100m 
    terminationMessagePath: /dev/termination-log
    volumeMounts:
    - mountPath: /var/run/secrets/k8s.io/servacc
      name: default-token-kvcqa
      readOnly: true
  dnsPolicy: ClusterFirst
  nodeName: gke-kubia-e8fe08b8-node-txje
  restartPolicy: Always
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  volumes:
  - name: default-token-kvcqa
    secret:
    secretName: default-token-kvcqa 
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: null
    status: "True"
    type: Ready
  containerStatuses:
  - containerID: docker://f0276994322d247ba...
    image: luksa/kubia
    imageID: docker://4c325bcc6b40c110226b89fe...
    lastState: {}
    name: kubia
    ready: true
    restartCount: 0
    state:
      running:
        startedAt: 2016-03-18T12:46:05Z
  hostIP: 10.132.0.4
  phase: Running
  podIP: 10.0.2.3
  startTime: 2016-03-18T12:44:32Z 
```
Pod definition主要由三个部分组成:
* metadata: name, namespace, labels和pod的其他信息
* spec: 对pod中内容的描述, 例如containers, environment variables, scheduler, volumes等信息
* status: pod当前运行的信息, 例如container的状态, pod的IP等信息

Pod definition中的**port**是纯粹的信息提醒, 并不具有强制力, 因此其他pod仍可向未定义的port发送信息, 该pod也可通过其他port与外部通信. 

### 2.2 Use kubectl create to create the pod
`kubectl create`可根据YAML文件创建pod, `kubectl get pod`会以YAML或JSON形式显示pod definition.
```bash
$ kubectl create -f kubia-manual.yaml
pod "kubia-manual" created

$ kubectl get pod kubia-manual -o yaml
$ kubectl get pod kubia-manual -o json
```

`kubectl get pods`可列出所有当前正在运行的pods.
```bash
$ kubectl get pods
NAME          READY STATUS  RESTARTS  AGE
kubia-manual  1/1   Running 0         32s
kubia-zxzij   1/1   Running 0         1d 
```

### 2.3 View application logs
通常放入container的程序应将日志直接输出到stdout或stderr, 而不是写入某个log文件中, 这样可以更加方便地浏览日志.

* container runtime(如Docker)会将stdout/stderr直接存入文件中(如`/var/lib/docker/containers`), 执行`docker logs`可查看container日志.
```bash
$ docker logs <container id>
```
* Kuberbetes可调用`kubectl logs`查看某个pod的log
```bash
$ kubectl logs kubia-manual
```
* 若pod中包含多个containers, 可添加`-c <container name>`来输出指定container的log
```bash
$ kubectl logs kubia-manual -c kubia
```

### 2.4 Send requests to the pod
Pod间的通信有多种方式实现, 最常用的方式是执行`kubectl expose`来创建一个service, 另一种方式是**port forwarding**. 执行`kubectl port-forward`可实现本机local port与pod的port的映射(例如: 将本机port 8888映射到pod的port 8080):
```bash
$ kubectl port-forward kubia-manual 8888:8080
... Forwarding from 127.0.0.1:8888 -> 8080
... Forwarding from [::1]:8888 -> 8080
```
![kubectl port-forward](/images/Kubernetes/pods-2-1.png)



## 3. Organize pods with labels
通常情况下, pod的数量会随着工程规模增加而变多. 对于一个microservice architecture, microservice的种类很容易达到20个以上; 由于不同版本的microservice可能包含不同的pod, 单个pod也可能被水平拓展, 从而导致pod数量达到上百个, 因此如何管理pod成为一个问题: k8s使用**labels**统一管理pods.

### 3.1 Introduction of labels
Label以**key-value**的形式挂在resource上. 需要使用部分resource时, 可使用**label selectors**来筛选resource. 每个resource可有一个或多个label, 且label可被修改, 添加和删除. 例如: 现在我们有一个pod defintiion名为`kubia-manual-with-labels.yaml`, 其拥有两个labels:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-manual-v2
  labels:
    creation_method: manual
    env: prod
spec:
  containers:
  - image: luksa/kubia
    name: kubia
    ports:
    - containerPort: 8080
      protocol: TCP
```

执行`kubectl create -f kubia-manual-with-labels.yaml`创建pod, 执行`kubectl get pods --show-labels`显示pods上的所有labels
```bash
$ kubectl get pods --show-labels
NAME            READY STATUS  RESTARTS  AGE LABELS
kubia-manual    1/1   Running 0         16m <none>
kubia-manual-v2 1/1   Running 0         2m  creat_method=manual,env=prod
kubia-zxzij     1/1   Running 0         1d  run=kubia
```
或添加`-L`指定一个或多个label:
```bash
$ kubectl get pods -L creation_method,env
NAME            READY STATUS  RESTARTS  AGE CREATION_METHOD ENV
kubia-manual    1/1   Running 0         16m <none>          <none>
kubia-manual-v2 1/1   Running 0         2m  manual          prod
kubia-zxzij     1/1   Running 0         1d  <none>          <none>
```

### 3.2 Modify labels of existing pods
k8s允许用户随时添加或修改pod的label.
1. Add a label to pod
  ```bash
  $ kubectl label pods kubia-manual creation_method=manual
  pod "kubia-manual" labeled
  ```
2. Change the existing labels, using "--overwrite" option
  ```bash
  $ kubectl label pods kubia-manual-v2 env=debug --overwrite
  pod "kubia-manual-v2" labeled
  ```


## 4 List subsets of pods through label selectors
**Label selector**可通过以下方式筛选resource:
* label的key为指定值
* label的key为指定值, 且label的value为指定值
* label的key为指定值, 且label的value不为指定值

以下是label selector使用的方法:
1. List all pods with specified key and value
  ```bash
  $ kubectl get pods -l creation_method=manual
  NAME            READY STATUS  RESTARTS AGE
  kubia-manual    1/1   Running 0        51m
  kubia-manual-v2 1/1   Running 0        37m
  ```
2. List all pods with specified key
  ```bash
  $ kubectl get pods -l env
  NAME            READY STATUS  RESTARTS AGE
  kubia-manual-v2 1/1   Running 0        37m
  ```
3. List all pods without specified key
  ```bash
  $ kubectl get pods -l '!env'
  NAME         READY STATUS  RESTARTS AGE
  kubia-manual 1/1   Running 0        51m
  kubia-zxzij  1/1   Running 0        10d
  ```

除上述方式外, label selector还支持一下方式筛选pod:
* `creation_method!=manual`: 筛选所有`creation_method`不为`manual`的pod
* `env in (prod,devel)`: 筛选所有`env`为`prod`或`devel`的pod
* `env notin (prod,devel)`: 筛选所有`env`不为`prod`且不为`devel`的pod
* 上述方式可用**comma**(逗号)组合, 例如: `app=pc, rel=beta`


## 5. Use labels and selectors to contrain pod scheduling
当pod被创建后, k8s会将其随机分配到cluster中的一个node. 但由于node并不是相同配置. 大部分情况下我们不需要对pod的分配做任何干预, 因为每个pod会获得所需的计算资源(CPU, 内存, 存储空间等); 但某些情况下可能需要手动分配pod, 尤其当node的硬件配置不一致时: 例如, 一个k8s cluster中一些node使用HDD, 另一些node使用SSD, 我们希望保证磁盘访问频繁的pod(如数据库应用)分配到使用SSD的node.
除了pod, k8s允许向node添加label, 并在pod definition中指定node的label.

### 5.1 Use labels for categorizing worker nodes
```bash
$ kubectl label node gke-kubia-85f6-node-0rrx gpu=true
node "gke-kubia-85f6-node-0rrx" labeled
```
然后在pod definition的YAML文件中添加node selector:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-gpu
spec:
  nodeSelector:
  gpu: "true"
  containers:
  - image: luksa/kubia
    name: kubia
```
运行该YAML文件时, pod会自动分配到拥有GPU的node上运行. 当然, 也可以将pod直接分配到某个node, 因为每个node都有一个唯一的label. 该label的key为**kubernetes.io/hostname**, label的value为**kunode的hostname**. 若在`nodeSelector`中使用该label, 则pod会与该node绑定; 若该node不可用, 则无法生成pod.


## 6.Annotate pods
除了labels, pods和其他k8s资源还拥有annotations. Annotations也以**key-value**形式存在, 但它并不负责管理resource, 而是用于说明resource, 例如: 创建该resource的用户姓名.
1. Look up an object's annotations: Annotation无法单独获取, pod definition或**kubectl describe**包含annotation.
2. Add and modify annotations: **kubectl annotate**可为对应resource添加annotation; 或key相同, 则覆盖value.
  ```bash
  $ kubectl annotate pod kubia-manual mycompany.com/someannotation="foo bar"
  pod "kubia-manual" annotated
  ```


## 7. Use namespaces to group resources
Label作为一种管理k8s资源的方法十分有效, 但存在以下问题:
* 查看资源时, 每次都需在命令后添加对应的label, 否则会看到所有资源
* 由于一个资源可以拥有多个label, 因此资源间会出现大量重叠label

总结来说, label只做到**资源分组**, 并不实现**资源隔离**, 因此k8s提供了**namespace**来隔离资源.

### 7.1 Introduction of namespace
Namespace可将资源隔离为不同group, 通常会按照开发环境来划分namespace(dev, stage, prod). 需要注意的是, 并不是所有资源都有namespace, 例如node, 这类资源称为**cluster-level resource**, 因此不能存在同名资源.
```bash
$ kubectl get ns
NAME        LABELS STATUS AGE
default     <none> Active 1h
kube-public <none> Active 1h
kube-system <none> Active 1h
```
若不指定namespace, 则kubectl默认在**default**的namespace下操作. 除了default之外, k8s会创建其他namespace. 若需要使用其他namespace下的resource, 可使用`--namespace`指定某个namespace
```bash
$ kubectl get pods --namespace kube-system
NAME                               READY STATUS  RESTARTS AGE
fluentd-cloud-kubia-e8fe-node-txje 1/1   Running 0        1h
heapster-v11-fz1ge                 1/1   Running 0        1h
kube-dns-v9-p8a4t                  0/4   Pending 0        1h
kube-ui-v4-kdlai                   1/1   Running 0        1h
l7-lb-controller-v0.5.2-bue96      2/2   Running 92       1h
```
需要注意的是, namespace提供的**隔离性**只面向user, 并不面向任何object. 例如, 现在k8s cluster中有两个namespace, 分别名为`foo`和`bar`, 用户在foo中查询的任何资源都只属于foo; 但若foo中的某个pod知道bar中某个pod的地址, 其仍可以向另一个namespace中的object发送信息.

### 7.2 Manage namespace
Namespace与其他资源一样, 都可通过`kubectl`命令或YAML文件创建.
1. 使用YAML或JSON文件
  ```yaml
  apiVersion: v1
  kind: Namespace
  metadata:
    name: custom-namespace
  ```
  使用kubectl将YAML文件发送给K8s API server:
  ```bash
  $ kubectl create -f custom-namespace.yaml
  namespace "custom-namespace" created
  ```
2. 使用`kubectl create namespace`
  ```bash
  $ kubectl create -f kubia-manual.yaml -n custom-namespace
  pod "kubia-manual" created
  ```

### 7.3 Manage resource in other namespace
若需要在其他namespace中创建资源, 可通过--namespace(或-n)或在metadata.namespace中指定namespace.
1. 执行kubectl命令时指定namespace
  ```bash
  $ kubectl create -f kubia-manual.yaml -n custom-namespace
  pod "kubia-manual" created
  ```
2. 在YAML文件中指定namespace
  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: my-pod
    namespace: test
  spec:
    containers:
    - name: my-container
      image: nginx
  ```


## 8. Stop and remove pods
1. Delete a pod by name
  ```bash
  $ kubectl delete pod kubia-gpu
  pod "kubia-gpu" deleted
  ```
  k8s会终止名为`kubia-gpudepod`中所有的container: k8s向container中的所有进程发送**SIGTERM**并等待一定时间(默认为30秒), 若进程没有在指定时间内关闭, 则向其发送**SIGKILL**以实行强制关闭.
2. Delete pods using label selectors
  若需要删除多个pod, 可使用label selector筛选.
  ```bash
  $ kubectl delete pods -l creation_method=manual
  pod "kubia-manual" deleted
  pod "kubia-manual-v2" deleted 
  ```
3. Delete pods by deleting the whole namespace
  若需要删除某个namespace中的所有pod, 可直接删除该namespace, k8s会自动删除该namespace中所有pod.
  ```bash
  $ kubectl delete ns custom-namespace
  namespace "custom-namespace" deleted
  ```
4. Delete all pods in a namespace, while keep the namespace
  若只想删除某个namespace, 不想删除namespace, 可使用`--all`.
  ```bash
  $ kubectl delete pods --all
  pod "kubia-zxzij" deleted
  ```
5. Delete all resources in a namespace
  若需要删除namespace中所有资源, 可执行以下命令.
  ```bash
  $ kubectl delete all --all
  pod "kubia-09as0" deleted
  replicationcontroller "kubia" deleted
  service "kubernetes" deleted
  service "kubia-http" deleted
  ```
  `all`表示所有类型的资源, `--all`表示某个类型下的所有resource