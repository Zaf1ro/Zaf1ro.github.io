---
title: Deployment
category:
  - K8s
tag:
  - K8s
abbrlink: 10cb
date: 2019-11-05 12:30:36
keywords:
description:
---

## 1. Update Applications Running in Pods
假设cluster中有一个ReplicationController或ReplicaSet管理多个Pods, 一个Service负责为Pods提供通信接口. 当Pod需要从v1版本提升到v2版本时, 有两个方法实现:
1. 删除所有已有的v1 Pods, 再部署v2 Pods
2. 启动一个v2 Pod, 并删除一个v1 Pod; 以此往复即可将所有Pod从v1修改为v2

上述两种方法都有其优点和缺陷:
1. 全部删除后再部署: 虽然操作简单, 不会占用过多资源; 但Pod所提供的服务会出现空档期: 以v1 Pod被关闭为起点, 以v2 Pod上线为终点
2. 新旧版本交替部署: 虽然Pod提供的服务不会产生中断, 但操作复杂, 新旧版本Pod可能会导致数据相互覆盖

### 1.1 Delete Old Pods and Replace with New Ones
假设cluster中有一个Replication管理三个版本为v1的Pods. 若需将Pod版本提升到v2, 可直接替换ReplicationController的template文件(只修改为v2 container image, 不修改label selector), 然后手动关闭所有v1 Pods, ReplicationController检测到replica count不足后会自动产生新的v2 Pod. 流程如下:
![Update pods by changing a ReplicationController’s pod template and deleting old Pods](/images/Kubernetes/deployment-1.png)

### 1.2 Spin up New Pods and Delete the Old Ones
若不想出现服务的空档期, 可在生成v2 Pod的同时保留v1 Pod, 分为两种方案:
1. Blue-green Deployment
创建新的ReplicationController(使用v2 container image和新的label selector)从而自动创建v2 Pods, 将service重定向到v2 Pods后删除旧版ReplicationController和其管理的v1 Pods. 流程如下:
![Switch a Service from the old pods to the new ones](/images/Kubernetes/deployment-2.png)

2. Rolling Update
上述做法虽然简单有效且避免了空档期, 但更新时由于Pod数量翻倍, 所以硬件的压力也增大. 为避免资源负担过重, 不能直接生成所有v2 Pods, 需要边生成v2 Pod, 边删除v1 Pod; 缺点在于操作繁琐, 极易产生错误. 流程如下:
![A rolling update of pods using two ReplicationControllers](/images/Kubernetes/deployment-3.png)



## 2. Perform an Automatic Rolling Update
相对于手动更新ReplicationController中的每个Pod, Kubernetes提供了自动rolling update功能.

### 2.1 Preparation
首先需要确定Pod中container所运行的程序: 假设container中运行名为kubia的NodeJS app监听8080端口, v1版本kubia接收到HTTP请求后回复"This is v1 running in pod", v2版本kubia接收到HTTP请求后回复"This is v2 running in pod". 创建含有v1 Pod的 ReplicationController:
```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: kubia-v1
spec:
  replicas: 3
  template:
    metadata:
      name: kubia
      labels:
        app: kubia
    spec:
      containers:
      - image: luksa/kubia:v1
        name: nodejs
```
创建Pod对应的Service:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia
spec:
  type: LoadBalancer
  selector:
    app: kubia
  ports:
  - port: 80
    targetPort: 8080
```
测试v1 Pod:
```sh
$ curl curl http://130.211.109.222
This is v1 running in pod
```

### 2.2 Perform a Rolling Update with kubectl
调用**kubectl rolling-update**可实现自动滚动更新Pod:
```sh
$ kubectl rolling-update kubia-v1 kubia-v2 --image=luksa/kubia:v2
Created kubia-v2
Scaling up kubia-v2 from 0 to 3, scaling down kubia-v1 from 3 to 0 (keep 3 pods available, don not exceed 4 pods)
...
```
上述命令会保留kubia-v1的ReplicationController, 并创建新的ReplicationController, 名为kubia-v2, 其中Pod使用**luksa/kubia:v2** image. 为避免kubia-v2覆盖kubia-v1, Kubernetes会为两个ReplicationController添加名为**deployment**的selector label, kubia-v1所管理的Pod也会被添加对应的label. 以下是刚调用命令后的情况:
![The state of the system immediately after starting the rolling update](/images/Kubernetes/deployment-4.png)

刚开始时kubia-v2的replica count被设置为0, 因此不会创建任何v2 Pod, 这是为了防止创建大量Pod而导致的资源不足. 之后Kubernetes会逐步增大kubia-v2的replica count, 并同时缩小kubia-v1的replica count, 从而达到v2 Pod逐步替代v1 Pod的目标:
![The Service is redirecting requests to both the old and new pods during the rolling update](/images/Kubernetes/deployment-5.png)

最终kubia-v2的replica count会增加到3, 而kubia-v1的replica count会减少到0. 但这种rolling update的方式已经被遗弃, 缺点有以下两点:
1. 调用kubectl时, kubectl会向API server发送多条HTTP请求来完成rolling update. 一旦client与master中途断开连接, 则更新中断且无法回滚
2. 该方法会向Pod和ReplicationController添加不必要的label



## 3. Use Deployment for Updating Apps
Deployment作为Kubernetes的一种Resource, 比ReplicationController和ReplicaSet维度更高. Deployment并不直接管理Pod, 而是通过创建一个ReplicaSet来实现管理. 因此用户不必手动操作ReplicaSet, deployment提供了完整的rolling update方案.

### 3.1 Create a Deployment
Deployment的创建与ReplicationController类似:
```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: kubia
spec:
  replicas: 3
  template:
    metadata:
      name: kubia
      labels:
        app: kubia
  spec:
    containers:
    - image: luksa/kubia:v1
      name: nodejs
```
Deployment的Service和ReplicationController相同:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia
spec:
  type: LoadBalancer
  selector:
    app: kubia
  ports:
  - port: 80
    targetPort: 8080
```
调用**kubectl create**即可创建Deployment, 其中**\-\-record**目的为记录kubia的每一次更新, 用于回滚操作:
```sh
$ kubectl create -f kubia-deployment-v1.yaml --record
deployment "kubia" created
```
可调用**kubectl rollout status**查看deployment的rollout状态:
```sh
$ kubectl rollout status deployment kubia
deployment kubia successfully rolled out
```
Deployment会自动创建Pod和ReplicaSet:
```sh
$ kubectl get po
NAME                   READY STATUS  RESTARTS AGE
kubia-1506449474-otnnh 1/1   Running 0        14s
kubia-1506449474-vmn7s 1/1   Running 0        14s
kubia-1506449474-xis6m 1/1   Running 0        14s
$ kubectl get replicasets
NAME             DESIRED CURRENT AGE
kubia-1506449474 3       3       10s
```

### 3.2 Update a Deployment
更新Deployment不需要指定新的ReplicaSet名字, 也不需要在乎ReplicaSet的label和replica count. Deployment支持两种更新策略:
1. RollingUpdate(默认值): 滚动更新, 边创建新的Pod, 边删除旧的Pod
2. Recreate: 先删除所有Pod, 再创建新的Pod

调用**kubectl set image**可直接替换Deployment中Pod的image:
```sh
$ kubectl set image deployment kubia nodejs=luksa/kubia:v2
deployment "kubia" image updated
```
注意: Deployment不会删除旧版本的ReplicaSet, 保留其用于回滚:
```sh
$ kubectl get rs
NAME             DESIRED CURRENT AGE
kubia-1506449474 0       0       24m
kubia-1581357123 3       3       23m
```
以下是修改Deployment的几种方式:
1. kubectl edit: 使用editor打开Deployment manifest, 修改后保存并推出editor
2. kubectl patch: 修改Deployment中的一个或多个属性
3. kubectl apply: 使用JSON或YAML文件替换或创建Deployment. 若存在同名Deployment, 则替换; 否则创建新的Deployment
4. kubectl replace: 使用JSON或YAML文件替换Deployment. 若不存在同名Deployment, 则报错
5. kubectl set image: 修改Deployment中的container image

### 3.3 Roll back a Deployment
首先创建一个需要回滚的情景: 假设v3 Pod中NodeJS app的前5个HTTP请求返回200 status code, 第6个HTTP请求开始返回500 status code. 调用**kubectl set image**更新Deployment来部署v3 Pod:
```sh
$ kubectl set image deployment kubia nodejs=luksa/kubia:v3
deployment "kubia" image updated
$ kubectl rollout status deployment kubia
deployment "kubia" successfully rolled out
```
调用**kubectl rollout undo**可回滚至上一个版本:
```sh
$ kubectl rollout undo deployment kubia
deployment "kubia" rolled back
```
之所以Deployment能实现回滚, 因为Deployment会在每次更新时记录并保留ReplicaSet. 即便新的Pod还未部署完毕, 也可回滚至前一个版本. 调用**kubectl rollout history**可查看所有revision history:
```sh
$ kubectl rollout history deployment kubia
deployments "kubia":
REVISION CHANGE-CAUSE
2        kubectl set image deployment kubia nodejs=luksa/kubia:v2
3        kubectl set image deployment kubia nodejs=luksa/kubia:v3
```
除了回滚到之前一个版本, 还可以标注**\-\-to-revision**来指明回滚的版本, 例如:
```sh
$ kubectl rollout undo deployment kubia --to-revision=1
```
以下是Deployment中ReplicaSet的保存记录:
![Deployment's ReplicaSets act as its revision history](/images/Kubernetes/deployment-6.png)
为防止revision history过长而导致大量旧版replicaSet占用资源, 可设置Deployment的revisionHistoryLimit属性来限制保留的ReplicaSet数量, 默认为10.

### 3.4 Control the Rate of the Rollout
Deployment提供了两个属性值来控制Deployment更新时资源占用情况:
* maxSurge: 超出desired replica count的Pod个数或比例
* maxUnavailable: 不可用的Pod数量或比例(相对于desired replica count来说)

```yaml
...
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
```
假设Deployment中ReplicaSet的replica count为3, maxSurge为1, maxUnavailable为0, 过程如下:
![Rolling update of a Deployment with maxSurge=1 and maxUnavailable=0](/images/Kubernetes/deployment-7.png)

假设Deployment中ReplicaSet的replica count为3, maxSurge为1, maxUnavailable为1, 过程如下:
![Rolling update of a Deployment with the maxSurge=1 and maxUnavailable=1](/images/Kubernetes/deployment-8.png)

注意: 不可将maxSurge和maxUnavailable都设置为0.

### 3.5 Pause the Rollout Process
调用**kubectl rollout pause**可暂停Pod的更新:
```sh
$ kubectl set image deployment kubia nodejs=luksa/kubia:v4
deployment "kubia" image updated
$ kubectl rollout pause deployment kubia
deployment "kubia" paused
```
调用**kubectl rollout resume**可恢复更新进程:
```sh
$ kubectl rollout resume deployment kubia
deployment "kubia" resumed
```
注意: 若Deployment被暂停, 则无法回滚该Deployment; 必须恢复运行后才可以回滚.

### 3.6 Block Rollouts of Bad Versions
Deployment还提供minReadySeconds属性来防止有缺陷的Pod被部署. minReadySeconds会在每个Pod部署之间设置等待时长, 只有上一个Pod处于Ready状态超过一定时间才会创建下一个Pod. 虽然这会导致每次rollout变慢, 但可有效防止意外情况发生.
minReadySeconds通常需要配合Readiness一起使用: 首先需在cluster中创建一个Deployment, Pod中运行的NodeJS app没有任何问题:
```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: kubia
spec:
  replicas: 3
  minReadySeconds: 10
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      name: kubia
      labels:
        app: kubia
    spec:
      containers:
      - image: luksa/kubia:v2
        name: nodejs
        readinessProbe:
          periodSeconds: 1
          httpGet:
            path: /
            port: 8080 
```
每个Pod中的container包含一个readiness, 每隔一秒会向8080端口发出HTTP请求. 之后再将Deployment从v2更新至v3: v3版本NodeJS app的前五次HTTP请求返回200 status code, 第六次及之后返回500 status code:
```sh
$ kubectl set image deployment kubia nodejs=luksa/kubia:v3
deployment "kubia" configured

$ kubectl rollout status deployment kubia
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...

$ kubectl get pods
NAME        READY STATUS  RESTARTS AGE
kubia-7ws0i 0/1   Running 0        30s
kubia-jvslk 1/1   Running 0        9m
kubia-pmb26 1/1   Running 0        9m
kubia-xk5g3 1/1   Running 0        8m
```
v3 Pod(kubia-7ws0i)虽然被创建, 但其状态无法变成Ready. 由于minReadySeconds为10秒, 所以Deployment在创建**kubia-7ws0i**后至少等待10秒, 且该Pod状态为Ready时才可以创建下一个v3 Pod; 但由于Readiness第六次发送HTTP请求后得到错误回复, 所以**kubia-7ws0i**的状态永远无法变为Ready, Deployment的rollout update也搁浅:
![Deployment blocked by a failing readiness probe in the new pod](/images/Kubernetes/deployment-9.png)

默认情况下, 若rollout在10分钟内没有完成, 则自动标记为fialed, 理由为ProgressDeadlineExceeded. 若想手动取消本次rollout, 可回滚至上一版本:
```sh
$ kubectl rollout undo deployment kubia
deployment "kubia" rolled back
```