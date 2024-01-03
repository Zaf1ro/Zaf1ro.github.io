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
Pod作为kubernetes中最小的单位, 可包含一个或多个container. 但一个pod中的多个container不能位于不同的nodes中.
![All containers of a pod run on the same node](/images/Kubernetes/pods-1.png)

### 1.1 Why we need pods
#### 1.1.1 Isolation between containers of the same pod
Container被设计用于运行单个进程, 但也可以运行多个进程. 之所以不推荐在单个container中运行多个进程, 因为进程之间的通信需要自己维护; 进程崩溃后也需要一种机制来重启; 每个进程的log也需要自行维护. 虽然container是互相独立的运行环境, 但单个pod中的所有container共享相同的linux namespace, 所以单个pod中的container共享同一个network和UTS namespace, 也共享同一个hostname和network interface; container之间也可通过IPC通信. 最新的Kubernetes和Docker版本中支持单个pod中的container共享同一PID.
Filesystem则不同, 由于每个container来自不同的container image, 所以不同container拥有独立的文件系统. 只有使用Volume时才能实现共享文件.

#### 1.1.2 How containers share the same IP and port
由于单个pod中的container共享一个loopback network interface, 应避免多个container使用同一port. 但不同pod的container则不存在这个问题, 因为不同pod拥有不同的port space.
同一Kubernetes cluster中的pod可直接通过内网IP与其他pod通信, 不需要NAT(Network Address Translation). 即使两个pod位于不同的node, pod之间的通信就像两台处于同一LAN(local area network)的电脑一样.
![Each pod gets a routable IP address and all other pods see the pod under that IP address](/images/Kubernetes/pods-2.png)

### 1.2  Organize containers across pods properly
虽然Kubernetes并不阻止多个app运行在单个pod的行为, 但也并不提倡这种做法, 原因如下:
1. 由于pod只能运行在单个node中, 浪费了其他node的资源(CPU, 内存等等)
2. Kubenetes无法实现scaling(均衡node负载)

单个Pod中放置多个pod的原因: 主进程需要一个或多个辅助进程. 例如web server需要一个downloader定期从外部下载server所需资源, 或者log rotator, data processor, communication adapter.
![A main container and containers that support the main one](/images/Kubernetes/pods-3.png)

多个container是否应该运行在同一pod可通过以下原则来判断:
1. containers是否可以运行在不同的pod中?
2. containers是否呈现为单个组件
3. containers是否作为一个整体被scaling



## 2. Create pod from YAML or JSON descriptors
### 2.1 YAML descriptor of an existing pod
运行**kubectl run** command可通过YAML或JSON文件创建一个全新的pod; 运行**kubectl get ... -o yaml** command可获取该pod的YAML文件定义. 
```yaml
$ kubectl get po kubia-zxzij -o yaml
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
1. Metadata: 包含name, namespace, labels和其他pod的信息
2. Spec: 包含对pod中内容的描述, 例如container, volumes和其他数据
3. Status: Pod当前运行的信息, 例如container的状态, pod的IP等信息

Pod definition中定义port是纯粹的信息提醒, 并不具有强制力. 其他pod仍可通过未定义的port来访问该pod, 该pod也可通过自身未定义的port与其他pod通信. 

### 2.2 Use kubectl create to create the pod
**kubectl create**可根据YAML文件创建pod, **kubectl get**可显示该pod的YAML或JSON definition
```bash
$ kubectl create -f kubia-manual.yaml
pod "kubia-manual" created

$ kubectl get po kubia-manual -o yaml
$ kubectl get po kubia-manual -o json
```

**kubectl get**也可用于列出所有当前正在运行的pods
```bash
$ kubectl get pods
NAME          READY STATUS  RESTARTS  AGE
kubia-manual  1/1   Running 0         32s
kubia-zxzij   1/1   Running 0         1d 
```

### 2.3 View application logs
当app被放入container后, 其log就被导向standard output stream和standard error stream, 而不是写入某个log文件中. 
* Docker可调用**docker logs**查看某个container的log
```bash
$ docker logs <container id>
```
* Kuberbetes可调用**kubectl logs**查看某个pod的log
```bash
$ kubectl logs kubia-manual
```
* 若pod中包含多个containers, 可添加**-c \<container name\>**来输出指定container的log
```bash
$ kubectl logs kubia-manual -c kubia
```

### 2.4 Send requests to the pod
Pod之间的通信有多种方式实现, 其中一种就是port forwarding. 调用**kubectl port-forward**可实现本机local port与pod的port的映射(例如: 将本机8888端口映射到pod的8080端口)
```bash
$ kubectl port-forward kubia-manual 8888:8080
... Forwarding from 127.0.0.1:8888 -> 8080
... Forwarding from [::1]:8888 -> 8080
```
![kubectl port-forward](/images/Kubernetes/pods-4.png)



## 3. Organize pods with labels
通常情况下, pod的数量会随着工程规模变大而变多. 若要设计一个microservice architecture, 使用到的microservice种类很容易达到20个以上; 而不同版本的microservice又包含不同的pod, 单个pod也可能被复制多次使用, 从而导致pod数量达到上百个. Kubernetes使用labels来统一化管理pods.

### 3.1 Introduction of labels
Label以key-value的格式挂在resource上, 当使用这些这些resource时, 可使用label selectors来筛选resource. 每个resource可有一个或多个label, label也可以被修改, 添加和删除. 例如: 每个pod拥有两个label
* app: pod所属的app
* rel: 版本类型, 例如: stable, beta或canary

### 3.2 Specify labels when creating a pod
在yaml的metadata.labels中可添加labels
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
调用**kubectl create -f kubia-manual-with-labels.yaml**即可创建pod并附加label. 调用**kubectl get pods --show-labels**可显示pods上的所有labels
```bash
$ kubectl get po --show-labels
NAME            READY STATUS  RESTARTS  AGE LABELS
kubia-manual    1/1   Running 0         16m <none>
kubia-manual-v2 1/1   Running 0         2m  creat_method=manual,env=prod
kubia-zxzij     1/1   Running 0         1d  run=kubia
```
或添加**-L**来指定一个或多个label:
```bash
$ kubectl get po -L creation_method,env
NAME            READY STATUS  RESTARTS  AGE CREATION_METHOD ENV
kubia-manual    1/1   Running 0         16m <none>          <none>
kubia-manual-v2 1/1   Running 0         2m  manual          prod
kubia-zxzij     1/1   Running 0         1d  <none>          <none>
```

### 3.3 Modify labels of existing pods
1. Add a label to pod
```bash
$ kubectl label pods kubia-manual creation_method=manual
pod "kubia-manual" labeled
```
2. Change the existing labels, using "--overwrite" option
```bash
$ kubectl label po kubia-manual-v2 env=debug --overwrite
pod "kubia-manual-v2" labeled
```



## 4 List subsets of pods through label selectors
Label selector可通过以下选项来选择resource:
* 匹配label的key
* 匹配label的key和value
* 匹配label的key, 但value不匹配

以下是label selector使用的方法:
1. List all pods with specified label
```bash
$ kubectl get pods -l creation_method=manual
NAME            READY STATUS  RESTARTS AGE
kubia-manual    1/1   Running 0        51m
kubia-manual-v2 1/1   Running 0        37m
```
2. List all pods with specified label's key
```bash
$ kubectl get po -l env
NAME            READY STATUS  RESTARTS AGE
kubia-manual-v2 1/1   Running 0        37m
```
3. List all pods without specified label's key
```bash
$ kubectl get po -l '!env'
NAME         READY STATUS  RESTARTS AGE
kubia-manual 1/1   Running 0        51m
kubia-zxzij  1/1   Running 0        10d
```
4. Use multiple conditions in a label selector
只需要用**comma**(逗号)将多个label分离开来, 就可以使用多个label作为label selector, 例如: app=pc, rel=beta



## 5. Use labels and selectors to contrain pod scheduling
当pod被创建后, Kubernetes会将其随机分配到一个node中并均衡负载. 但由于node并不是相同配置, 可能某些node拥有更多的存储空间, 而database又需要巨大的空间来存储数据, 因此运行database的pod应被分配到该node更合理. 为让pod运行在更合适的node上, 需要为node附上label, 并在创建pod时使用label selector选择对应的node.

### 5.1 Use labels for categorizing worker nodes
Label可以附加在Kubernetes中的任何resource上, resource当然不局限于pods, 也包含node. 假设pod需要具备GPU的node: 首先需要为具有GPU的node加上label
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
这样在运行YAML文件后, pod就会自动分配到具有GPU的node上运行. 当然, 也可以将pod直接分配到某个node, 因为每个node都有一个唯一的label: key为**kubernetes.io/hostname**, value则是node的专属名称. 若Pod definition的YAML文件中nodeSelector使用该label, 则pod会与该node绑定. 当node不可用时, pod也会无法使用.



## 6.Annotate pods
类似于labels, pods和其他object还拥有annotations. Annotations也以key-value形式存在, 但它并不负责管理resource, 而是用于说明resource. Annotations通常用于描述resource, 例如: 创建该resource的用户姓名.

1. Look up an object's annotations
Annotations无法单独获取, 但可通过获取YAML或**kubectl describe**来获取annotation.
2. Add and modify annotations
**kubectl annotate**可为resource添加一个新的annotation; 或key相同, 则覆盖之前的value值
```bash
$ kubectl annotate pod kubia-manual mycompany.com/someannotation="foo bar"
pod "kubia-manual" annotated
```



## 7. Use namespaces to group resources
Labels作为一个管理resource的方法非常有效, 但需要在每次操作时在命令后添加对应的label, 而且label并不能隔离resource. 于是Kubernetes提出namespace来隔离不同namespace下的resource.

### 7.1 Introduction of namespace
默认情况下, kubectl会在名为**default**的namespace下工作:
```bash
$ kubectl get ns
NAME        LABELS STATUS AGE
default     <none> Active 1h
kube-public <none> Active 1h
kube-system <none> Active 1h
```
除了default之外, kubernetes会创建其他namespace. 如果需要使用其他namespace下的resource, 可使用**--namespace**来指定某个namespace
```bash
$ kubectl get po --namespace kube-system
NAME                               READY STATUS  RESTARTS AGE
fluentd-cloud-kubia-e8fe-node-txje 1/1   Running 0        1h
heapster-v11-fz1ge                 1/1   Running 0        1h
kube-dns-v9-p8a4t                  0/4   Pending 0        1h
kube-ui-v4-kdlai                   1/1   Running 0        1h
l7-lb-controller-v0.5.2-bue96      2/2   Running 92       1h
```

### 7.2 Manage namespace
namespace有以下两种方式创建:
1. 创建并运行YAML或JSON文件
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: custom-namespace
```
2. 调用**kubectl create namespace \<custom-namespace\>**

当创建resource时, 若需为其指定namespace, 则调用:
```bash
$ kubectl create -f kubia-manual.yaml -n custom-namespace
pod "kubia-manual" created
```



## 8. Stop and remove pods
1. Delete a pod by name
```bash
$ kubectl delete pod kubia-gpu
pod "kubia-gpu" deleted
```
    Kubernetes会终止所有kubia-gpu中的所有container: 向container中的所有进程发送SIGTERM signal并等待30秒, 若30秒后进程没有自行关闭, 则向其发送SIGKILL signal实行强制关闭.
2. Delete pods using label selectors
```bash
$ kubectl delete pod -l creation_method=manual
pod "kubia-manual" deleted
pod "kubia-manual-v2" deleted 
```
3. Delete pods by deleting the whole namespace
```bash
$ kubectl delete ns custom-namespace
namespace "custom-namespace" deleted
```
4. Delete all pods in a namespace, while keep the namespace
```bash
$ kubectl delete pod --all
pod "kubia-zxzij" deleted
```
5. Delete all resources in a namespace
```bash
$ kubectl delete all --all
pod "kubia-09as0" deleted
replicationcontroller "kubia" deleted
service "kubernetes" deleted
service "kubia-http" deleted
```
    **all**:所有类型的resource, **--all**:指定类型的所有resource