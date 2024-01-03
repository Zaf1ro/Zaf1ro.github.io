---
title: Replication Controllers
category:
  - K8s
tag:
  - K8s
abbrlink: '17e0'
date: 2019-10-17 08:32:29
keywords:
description:
---

## 1. Introduction
当创造了一个新的pod后, Kubernetes会为其自动分配至一个worker node并开始运行. 若pod中的主进程停止运行或所在的worker node不可用, 则pod也不可用. 为此Kubernetes提供了Replication Controller和Deployment来维护pod运行: 当pod中的主进程停止运行或所在的worker node不可用时, Kubernetes会重启或再分配pod到新的worker node. 但若出现异常情况, 例如: 内存溢出, 死锁等导致的进程无响应, Kubernetes不会发觉并重启pod. 因此需要从外部不断检查app的状态.

## 2 liveness probes
Kubernetes可通过liveness probes来探测container是否运行. 每个pod中的每个container都可指定一个liveness probe来定期执行probe并在probe运行失败后重启container. Liveness probe有三种探测container的方式:
1. Probe向container的IP address发送HTTP GET请求. 若probe收到错误的response code或没收到任何response, 则重启container.
2. Probe会向container的指定port发起TCP连接请求. 若连接请求失败, 则重启container.
3. Probe在container内存执行**exec** command并检查exit status code. 若exit status code不为0, 则重启container

### 2.1 Create an HTTP-based liveness probe
当创建pod时, 可为每个pod制定一个liveness probe. 下面例子中probe每隔一段时间(默认为10秒)会对产生的container下**/**路径和**8080**端口进行HTTP访问.
```yaml
apiVersion: v1
kind: pod
metadata:
  name: pod-name
spec:
  containers:
  - image: image-name
    name: container-name
    livenessProbe:
      httpGet:
        path: /
        port: 8080 
```
当probe发现container返回错误response code或无响应时会自动重启该container. 当运行**kubectl get pods**时, RESTARTS一列会显示该pod中的container被重启多少次:
```sh
$ kubectl get po kubia-liveness
NAME     READY STATUS  RESTARTS AGE
pod-name 1/1   Running 1        2m
```
通过**kubectl describe pod**可获得probe更详细的信息:
```sh
Name: pod-name
...
Containers:
  kubia:
  Container ID: docker://480986f8
  Image: image-name
  Image ID: docker://sha256:2b208508
  Port:
  State: Running
    Started: Sun, 14 May 2017 11:41:40 +0200
  Last State: Terminated
    Reason: Error
    Exit Code: 137
    Started: Mon, 01 Jan 0001 00:00:00 +0000
    Finished: Sun, 14 May 2017 11:41:38 +0200
  Ready: True
  Restart Count: 1
  Liveness: http-get http://:8080/ delay=0s timeout=1s
            period=10s #success=1 #failure=3
  ...
Events:
  ... 
  Killing container with id docker://95246981:pod "image-name" ...
```
上述表示当前运行的container之前被终止过, exit code为137 (exit code为128+x, x表示真正的exit code), 也就是9 (由Kubernetes发出的SIGKILL signal). 

### 2.2 Configure additional properties of the liveness probe
每个liveness probe都有属性, 包括:
* initialDelaySeconds: container启动后多少秒后启动probe, 默认为0
* timeoutSeconds: probe发出请求后多少秒内container应回复, 默认为1
* periodSeconds: probe发出请求的间隔时间, 默认为10
* failureThreshold: probe探测到container失败后, 重启container的最大次数, 默认为3, 最小为1. 

HTTP probe提供了更多属性:
* host: Hostname, 默认为pod IP
* scheme: 连接container的方式, HTTP或HTTPS, 默认为HTTP
* path: HTTP资源路径
* httpHeaders: HTTP Header
* port: HTTP port, 范围为[1, 65535]

### 2.3 Create effective liveness probes
Pod中的每个container都应有一个liveness probe检测其状态. 但也要注意, liveness probe只应检测由container内部产生的异常, 而不是外部因素导致的运行错误, 例如: 当使用liveness probe检测server运行状况时, 不应因database导致server的异常让server不断重启. 
Liveness probe的设计必须轻量级, 每个container都有自己的资源上限, liveness probe与container共享该资源; 当liveness probe消耗太多CPU时, container则受限于CPU的不足. 
即使将failureThreshold设为1, Kubernetes也会在放弃container之前使用probe来多次探测container. 所以使用者不必设计retry loop使用probe.
Probe由worker node上的kubelet管理并实现, 所以当worker node不可用时, probe也不再可用. 为保证pod会被分配到其他worker node上, 需使用ReplicationController或其他方法.



## 3. ReplicationControllers
ReplicationController作为Kubernetes的一种resource, 能确保pods一直保持运行. 无论是pod停止运行, 或node不可用, ReplicationController都会创造替代的pod.  下图中ReplicationController管理Pod B; 当Node 1不可用时, ReplicationController会在Node 2创建一个Pod B来替代旧的Pod.
![When a node fails, only pods backed by a ReplicationController are recreated](/images/Kubernetes/rc-1.png)

### 3.1 The Operation of a ReplicationController
ReplicationController会通过label selector来监控特定的Pod set并确保这些Pods维持在一定数量. 若当前运行的Pod数量少于目标数量, 则创建Pod; 若当前运行的Pod数量多于目标数量, 则移除部分Pod. 以下操作会导致运行的Pod数量多于目标数量:
* 创建相同类型(Pod的label与ReplicationController的label selector相等)的Pod
* 其他类型的Pod被修改为相同类型
* 目标Pod数量被修改为更小数值

ReplicationmController的运行过程如下:
![A ReplicationController’s reconciliation loop](/images/Kubernetes/rc-2.png)

ReplicationController有三大属性值:
* label selector: ReplicationController管理的Pod范围
* replica count: 被管理的Pod所需的运行数量
* pod template: 创建Pod的模板

Kubernetes允许在ReplicationController运行过程中修改其label selector和pod template, 但并不会影响当前运行的Pod. 例如: label selector被修改后, ReplicationController并不会移除当前pod, 而是放任这些pod继续运行; pod template被修改后, ReplicationController当前管理的pod不会被修改, 之后新建的pod才会遵循修改后的pod template.

ReplicationController对比单独运行Pod, 有以下几点优点:
* 当Pod停止工作时, 确保新的Pod会被创建并持续运行
* 当Node不可用时, 会在其他可用的Node中创建Pod替代
* 提供了一种horizontal scaling of pods

### 3.2 Create a ReplicationController
ReplicationController同样通过JSON或YAML文件创建:
```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: kubia
spec:
  replicas: 3
  selector:
    app: kubia
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
      - name: kubia
        image: image-name
        ports:
        - containerPort: 8080 
```
上述YAML文件中ReplicationController使用**app=kubia**作为label selector, 所有携带该label的Pod都处于ReplicationController的管理之中; ReplicationController会保证随时都有3个该类型的Pod在cluster中运行, 当前运行的Pod数量不足时, 会调用**template**中的模板创建新的Pod.
注意: 若template中的labels与selector不同, 则ReplicationController会不断创建Pod, 因为所创建的Pod无法满足selector标示的label. 为避免这种情况出现, 可将selector域置空, Kubernetes会自动将Pod template中的labels赋为label selector.

### 3.3 ReplicationController in action
运行**kubectl create**创建ReplicationController:
```sh
$ kubectl create -f kubia-rc.yaml
replicationcontroller "kubia" created

$ kubectl get pods
NAME        READY STATUS            RESTARTS AGE
kubia-53thy 0/1   ContainerCreating 0        2s
kubia-k0xz6 0/1   ContainerCreating 0        2s
kubia-q3vkg 0/1   ContainerCreating 0        2s
```
当Pod数量小于目标Pod数量时, ReplicationController会自动创建新的Pod:
```sh
$ kubectl delete pod kubia-53thy
pod "kubia-53thy" deleted

$ kubectl get pods
NAME        READY STATUS            RESTARTS AGE
kubia-53thy 1/1   Terminating       0        3m
kubia-oini2 0/1   ContainerCreating 0        2s
kubia-k0xz6 1/1   Running           0        3m
kubia-q3vkg 1/1   Running           0        3m
```
调用**kubectl get rc**可显示cluster中所有的ReplicationController:
```sh
$ kubectl get rc
NAME  DESIRED CURRENT READY AGE
kubia 3       3       2     3m
```
以下是node不可用时的情况(本例中共有3个worker nodes, 3个Pods):
```sh
----- Disconnect one of worker nodes from the network -----

$ kubectl get node
NAME            STATUS   AGE
kubia-pool-opc5 Ready    5h
kubia-pool-s8gj Ready    5h
kubia-pool-zwko NotReady 5h

$ kubectl get pods
NAME        READY STATUS  RESTARTS AGE
kubia-oini2 1/1   Running 0        10m
kubia-k0xz6 1/1   Running 0        10m
kubia-q3vkg 1/1   Unknown 0        10m
kubia-dmdck 1/1   Running 0        5s
```
当worker node重新连接后, 其status将会变为Ready, 但Unknown状态的pod将会被删除.

### 3.4 Move pods in and out of the scope of a ReplicationController
1. Add Labels to Pods Managed by a ReplicationController
ReplicationController并不会在意pod上的其他label
```sh
$ kubectl label pod kubia-dmdck type=special
pod "kubia-dmdck" labeled

$ kubectl get pods --show-labels
NAME        READY STATUS  RESTARTS AGE LABELS
kubia-oini2 1/1   Running 0        11m app=kubia
kubia-k0xz6 1/1   Running 0        11m app=kubia
kubia-dmdck 1/1   Running 0        1m  app=kubia,type=special
```
2. Change the Labels of a Managed Pod
修改Pod的label可能导致Pod脱离ReplicationController的管理范围, ReplicationController会重新创建一个Pod作为替代
```sh
$ kubectl label pod kubia-dmdck app=foo --overwrite
pod "kubia-dmdck" labeled

$ kubectl get pods -L app
NAME        READY STATUS            RESTARTS AGE APP
kubia-2qneh 0/1   ContainerCreating 0        2s  kubia
kubia-oini2 1/1   Running           0        20m kubia
kubia-k0xz6 1/1   Running           0        20m kubia
kubia-dmdck 1/1   Running           0        10m foo 
```
![Removing a pod from the scope of a ReplicationController by changing its labels](/images/Kubernetes/rc-3.png)

3. Remove Pods from ReplicationControllers in Practice
当需要对特定Pod进行操作时, 需将Pod从ReplicationController中移除
4. Change the ReplicationController's label selector
当ReplicationController的selector被修改后, 之前运行的Pod会脱离管理并继续运行, ReplicationController会创建新的Pod来保住replica count. 但绝大多数情况下都不需要修改selector.

### 3.5 Change the pod template 
ReplicationController中的Pod template也可在任何时刻被修改. 修改后不会影响已经运行的Pod, 但ReplicationController之后新建的Pod会遵循新的Pod template.
![Changing a ReplicationController’s pod template only affects pods created afterward and has no effect on existing pods](/images/Kubernetes/rc-4.png)

运行**kubectl edit rc <rc-name>**会打开ReplicationController的YAML definition(使用默认editor), 修改后并保存即可. 若需修改editor, 可修改环境变量**KUBE_EDUTOR**为想要的editor路径.

### 3.6 Horizontally scaling pods
有两种方法改变replica count:
1. 调用**kubectl scale** command直接修改replica count:
```sh
$ kubectl scale rc kubia --replicas=<num-of-desired-replicas>
```
2. 调用**kubectl edit** command修改ReplicationController的YAML definition:
```sh
kubectl edit rc kubia
```

### 3.7 Delete a ReplicationController
当运行**kubectl delete** command不仅会删除ReplicationController, 还会删除其管理下的所有pods. 若想在删除ReplicationController的前提下保留其pods, 可加上**cascade=false** option:
```sh
$ kubectl delete rc kubia --cascade=false
replicationcontroller "kubia" deleted
```



## 4. ReplicaSet
ReplicaSet作为ReplicationController的增强版, 其具有和ReplicationController相同的功能: 维持cluster中运行replica count个pod. ReplicaSet相比于ReplicationController, 最大的区别在于: ReplicaSet支持set-based selector. 例如: ReplicationController不支持selector中同一key拥有多个value值(例如: env=devel, env=production); ReplicationController也不支持单个key的selector.
```yaml
apiVersion: apps/v1beta2
kind: ReplicaSet
metadata:
  name: kubia
spec:
  replicas: 3
  selector:
    matchLabels:
      app: kubia
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
      - name: kubia
        image: luksa/kubia 
```

Label selector是ReplicaSet与ReplicationController在YAML中唯一不同之处. Replica使用**matchLabels**表示简单的label匹配(与ReplicationController相同), **matchExpressions**表示更复杂的label匹配. 以下是matchExpressions selector的例子:
```yaml
selector:
  matchExpressions:
  - key: app
    operator: In
    values:
    - kubia 
```

除了key和value, matchExpressions加入了operator选项表示value的匹配模式:
1. In: Pod的value需与ReplicaSet中的其中一个value相同
2. NotIn: Pod的value需与ReplicaSet中的所有value不同
3. Exists: Pod需拥有和ReplicaSet相同的key, 不可设置value域
4. DoesNotExist: Pod不需拥有和ReplicaSet相同的key, 不可设置value域

若同时使用了matchLabels和matchExpressions, 则Pod只要匹配其中一个即可归入该ReplicaSet的管辖内.



## 5. DaemonSet
ReplicationController和ReplicaSet都可让特定数量的Pod运行在Kubernetes Cluster之中, 但却无法保证Pod被分配到了哪个worker node. 如果需要每个worker node上都运行pod, 例如: 用于收集resource信息的log collector, 则需要DaemonSet.
![DaemonSets run only a single pod replica on each node, whereas ReplicaSets scatter them around the whole cluster randomly](/images/Kubernetes/rc-5.png)

DaemonSet不需要确认replica count, 因为Pod数量与worker node的数量相关. 当某个worker node不可用时, DaemonSet不会重新创建worker node上的pod.
除了label selector, DaemonSet还提供了node selector, 可以确保pod在哪些worker node上进行. 下面的DaemonSet只会在具有**disk: ssd** label的worker node上创建Pod:
```yaml
apiVersion: apps/v1beta2
kind: DaemonSet
metadata:
  name: ssd-monitor
spec:
  selector:
    matchLabels:
      app: ssd-monitor
  template:
    metadata:
      labels:
        app: ssd-monitor
    spec:
      nodeSelector:
        disk: ssd
      containers:
      - name: main
        image: luksa/ssd-monitor
```

以下是DaemonSet的运行结果:
![Using a DaemonSet with a node selector to deploy system pods only on certain nodes](/images/Kubernetes/rc-6.png)

当worker node移除或修改**app: ssd** label后, DaemonSet会删除该worker node上的Pod:
```sh
$ kubectl label node minikube disk=hdd --overwrite
node "minikube" labeled

$ kubectl get pods
NAME              READY STATUS      RESTARTS AGE
ssd-monitor-hgxwq 1/1   Terminating 0        4m
```



## 6. Job
Job作为Kubernetes的一种resource, 会在Pod被中断或所在的worker node不可用时自动重启. 但与ReplicaSet和ReplicationController不同的是, Job管理的Pod在成功运行后会自行结束, 而不是继续创建新的Pod重新执行. 下面是worker node不可用时发生的情况:
![Pods managed by Jobs are rescheduled until they finish successfullys](/images/Kubernetes/rc-7.png)

### 6.1 Define a Job resource
Pod默认情况下restartPolicy为Always, 但Job所管理的Pod必须显式标记restartPolicy为OnFailure或Never.
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-job
spec:
  template:
    metadata:
      labels:
        app: batch-job
    spec:
      restartPolicy: OnFailure
      containers:
      - name: main
        image: luksa/batch-job
```

### 6.2 Job in a Pod
```sh
$ kubectl get jobs
NAME      DESIRED SUCCESSFUL AGE
batch-job 1       0          2s

$ kubectl get pods
NAME            READY STATUS  RESTARTS AGE
batch-job-28qf4 1/1   Running 0        4s

----- After pod finish successfully -----

$ kubectl get pods -a
NAME            READY STATUS    RESTARTS AGE
batch-job-28qf4 0/1   Completed 0        2m

$ kubectl get job
NAME      DESIRED SUCCESSFUL AGE
batch-job 1       1          3m
```
注意: kubectl get必须加上**--show-all**或**-a**时才能显示已完成的Pod. 

### 6.3 Run Multiple Pod Instance in a Job
Job还包含两个属性:
* completions: 需要多少个Pod执行
* parallelism: 同一时刻可运行多少个Pod

通过设置这两个属性, 可实现串行或并行运行Job:
1. Run Job Pods Sequentially
当Job需要多个Pod运行且未设置parallelism时, Job会一个个创建Pod并等待其运行完毕
```sh
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-completion-batch-job
spec:
  completions: 5
  template:
    ...
```
2. Run Job Pods in Parallel
当Job需要多个Pod运行且设置了parallelism时, Job会同时运行多个Pod
```sh
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-completion-batch-job
spec:
  completions: 5
  parallelism: 2
  template:
    ...
```

调用**kubectl scale** command会修改Job的parallelism值, 不会修改completions值. 通过设置spec.activeDeadlineSeconds值可规定Pod超过运行时长后自动终止.



## 7. CronJob
Job虽然可执行单个或多个Pod并等待其完成, 但无法规定Pod在某个特定时刻运行. CronJob作为Kubernetes的一种resource, 具有定时执行功能, 精确到秒. 假设我们需要每隔15分钟执行一次Job:
```sh
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: batch-job-every-fifteen-minutes
spec:
  schedule: "0,15,30,45 * * * *"
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: periodic-batch-job
        spec:
          restartPolicy: OnFailure
          containers:
          - name: main
            image: luksa/batch-job 
```
CronJob中schedule域分为5个值:
* Minute
* Hour 
* Day of month
* Month
* Day of week

若需每个月第一天每隔30分钟执行一次, 可设置为"0, 30 * 1 * *"; 若需每个周日的3AM执行, 可设置为"0 3 * * 0". 一般来说, Pod的创建会比规定的时间晚一点, 若对Pod的执行时刻有严格限制, 可在YAML文件中设置startingDeadlineSeconds. 例如: 
```yaml
apiVersion: batch/v1beta1
kind: CronJob
spec:
  schedule: "30 10 * * *"
  startingDeadlineSeconds: 15
  ...
```
上述例子中, 若Pod没有在10:30:15之前创建Pod, 则本次job不会运行并直接标记为Failed
