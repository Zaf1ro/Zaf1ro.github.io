---
title: Volumes
abbrlink: f56f
date: 2019-10-24 12:57:55
category:
  - K8s
tag:
  - K8s
keywords:
description:
---

## 1. Introduction
由于每个container都有独立的filesystem, 会带来两个问题:
* 即使两个container位于同一pod, 它们也无法获取彼此的文件
* 当container重启时, 重启后的container无法获取之前的无法

因此我们需要一种方法来让两个container(同一pod的两个container, 或重启前与重启后的container)共享文件: volume并不是k8s的一种resource, 而是作为pod的一个组成部分. Volume具有以下属性:
* 无法通过YAML创建一个单独的volume
* Pod创建时会自动生成volume, pod被销毁时也会自动删除volume
* 若pod内有多个container, 则这些container共享该volume
* 由于volume的生存周期与volume绑定, 因此重启container不影响volume, 且重启后的container依然可看到重启前container写入的文件

需要注意的是, 只有volume被mount到container上时, container才能访问volume. 假设一个pod中有三个container, 分别为:
* web server: 负责从`/var/htdocs/`路径中读取HTML文件, 并将日志存入`/var/logs/`路径中
* content agent: 负责生成HTML文件并保存到`/var/html/`路径中
* log rotator: 负责处理`/var/logs/`路径中的日志文件

由于每个container各自拥有独立的filesystem, 因此web server生成的日志无法被log rotator获取, content agent生成的HTML也无法被web server获取:
![Three containers of the same pod without shared storage](/images/Kubernetes/vol-1-1.png)

添加两个volume后, container就可以通过volume共享文件:
![Three containers sharing two volumes mounted at various mount paths](/images/Kubernetes/vol-1-2.png)

K8s提供了多种volume类型:
* emptyDir: 生成一个空文件夹, 用于存放临时数据
* hostPath: 将node上的文件系统mount到pod中
* gitRepo: volume中的内容由git repository初始化
* nfs: 将NFS mount到pod中
* gcePersistentDisk, awsElasticBlockStore, azureDisk: 将云服务提供商的存储服务mount到pod中
* cinder, cephfs, iscsi, flocker, glusterfs, quobyte, rbd, flexVolume, vsphereVolume, photonPersistentDisk, scaleIO: 将不同类型的网络存储服务mount到pod中
* configMap, secret, downwardAPI: 将k8s资源和cluster信息mount到pod中
* persistentVolumeClaim: 将persistent volume(PV)中的文件mount到pod中, 

一个pod中可使用多个不同类型的volume, pod中的container需mount每一个需要使用的volume.


## 2. Use Volumes to Share Data between Containers
### 2.1 emptyDir Volume
`emptyDir`是最简单的volume类型, 其会提供一个空文件夹, container可向volume中写入或读取文件, 也可实现不同container共享文件. 但缺陷也明显: 由于emptyDir的生存周期与pod绑定, 因此pod删除后emptyDir也会消失.
假设在一个pod中运行两个container, 一个由Nginx运行的web server, 一个fortune命令(定期将一个随机字段写入文件中)执行的content agent. Pod的YAML文件如下:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune
spec:
  containers:
  - image: luksa/fortune
    name: html-generator
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
      readOnly: true
    ports:
    - containerPort: 80
      protocol: TCP
  volumes:
  - name: html
    emptyDir: {}
```
上述pod中存在两个container:
* Nginx默认读取`/usr/share/nginx/html`目录中的HTML文件, 因此将volume挂载到该路径上
* fortune脚本会每隔10秒向`/var/htdocs/index.html`文件中写入随机字段, 因此将volume挂载到`/var/htdocs`上

这样nginx就可从HTML文件中读取到fortune写入的数据, nginx再将更新后的数据发送给用户. emptyDir默认将数据保存在node的磁盘上, 因此文件读写速度与node上的磁盘类型相关. K8s支持修改emptyDir的存储媒介, 如内存:
```yaml
volumes:
- name: html
  emptyDir:
  medium: Memory
```

### 2.2 gitRepo Volume
gitRepo作为emptyDir的增强版, 会先创建一个空的volume, 再从git repository复制数据到volume中, 流程如下:
![A gitRepo volume is an emptyDir volume initially populated with the contents of a Git repository](/images/Kubernetes/vol-2-1.png)

需要注意的是, gitRepo被创建后, 若其他开发者向该仓库push commit, volume中的数据不会同步更新; 但若pod由ReplicationController管理, 则pod被删除后, 新产生的pod会拥有最新的commit数据.
假设一个git repo中存有HTML文件, web server会从该repo中读取HTML, pod的YAML文件如下:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gitrepo-volume-pod
spec:
  containers:
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
      readOnly: true
    ports:
    - containerPort: 80
      protocol: TCP
  volumes:
  - name: html
    gitRepo:
      repository: https://github.com/luksa/kubia-website-example.git
      revision: master
      directory: . 
```
当创建该pod时, k8s会先创建一个空的文件夹, 并将git repo中的数据clone到volume中. 若未将`directory`设置为`.`, 则会将repo中的数据clone到`kubia-website-example`文件夹中.
虽然gitRepo不提供同步功能, 但Docker Hub上有很多container image实现该功能, 这类container被称为**sidecar container**. sidecar container 虽然与web-server container处于同一Pod, 但却为辅助web-server运行而存在.
gitRepo还存在一个缺陷: 不支持从private git repo中复制数据, 因为gitRepo不支持SSH协议; 若需要从private git repo复制数据, 还需要其他sidebar container的帮助. 需要注意的是, gitRepo与emptyDir的生存周期相同, 都会在pod被删除后一并删除.


## 3. Access Files on the Worker Node's Filesystem
一般情况下, pod无需关心在哪个node上运行; 但有些pod(如DaemonSet管理的pod)需要读取node上的文件, 或使用node的文件系统访问node的设备. K8s提供了**hostPath**将node上的某个路径mount到container的指定路径:
![A hostPath volume mounts a file or directory on the worker node into the container’s filesystem](/images/Kubernetes/vol-3-1.png)

下面YAML文件创造了一个pod, 将node的`/data`文件夹mount到`test-container`的`/test-pd`. 添加修改或删除container中`/test-pd`内文件都会同步到node上的`/data`, 反之同理.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: k8s.gcr.io/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /test-pd
      name: test-volume
  volumes:
  - name: test-volume
    hostPath:
      path: /data
      type: Directory
```
相对于emptyDir和gitRepo, hostPath提供了persistent storage(可持续存储), 意味着pod被删除后volume中的数据不会消失, 只要pod被部署到相同node上, 就可以重新访问该数据. 该volume的缺陷也很明显: 一旦将pod重新部署到其他node, 则无法访问数据, 因此不推荐将hostPath作为一个数据库应用的存储方式, 只有需要访问node的系统文件时再使用hostPath.
 

## 4. Persistent Storage
若pod需要将数据存储到磁盘上, 且被重新部署到其他node上时仍需访问该数据, 则上述volume皆无法实现, 因为volume的生存周期不能与pod绑定, volume的存储位置不能与node绑定. 不同的云服务提供商提供了不同的NAS(network-attached storage)来解决该问题. 以下会以GCP(Google Cloud Platform)和AWS(Amazon Web Services)为例, 部署包含MongoDB的pod.

### 4.1 GCP Persistent Disk
GCP提供自家的persistent disk. 该persistent disk不属于任何namespace或cluster, 只与zone绑定, 因此cluster必须与persistent disk处于同一zone. 运行gcloud命令可查看当前所有cluster所在的zone:
```sh
$ gcloud container clusters list
NAME  ZONE           MASTER_VERSION MASTER_IP ...
kubia europe-west1-b 1.2.5          104.155.84.137 ...
```
可以发现kubia位于`europe-west1-b`, 因此我们需要在该zone创建GCE persistent disk.
```sh
$ gcloud compute disks create --size=1GiB --zone=europe-west1-b mongodb
NAME    ZONE           SIZE_GB TYPE        STATUS
mongodb europe-west1-b 1       pd-standard READY
```
上述命令在`europe-west1-b`创造了一个1Gb大小的persistent disk, 现在可创造pod并使用该persistent disk:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mongodb
spec:
  volumes:
  - name: mongodb-data
    gcePersistentDisk:
      pdName: mongodb
      fsType: ext4
  containers:
  - image: mongo
    name: mongodb
    volumeMounts:
    - name: mongodb-data
      mountPath: /data/db
  ports:
    - containerPort: 27017
      protocol: TCP
```
通过标注gcePersistentDisk可将GCE persistent disk添加到pod中, 即使该pod被移除, persistent disk中的数据也不会受影响:
![A pod with a single container running MongoDB, which mounts a volume referencing an external GCE Persistent Disk](/images/Kubernetes/vol-4-1.png)

### 4.2 AWS Persistent Data
AWS和Azure也提供了persistent disk, 步骤与GCP的NAS相同: 在cluster所在的zone中创建volume, 再在pod中声明该volume:
```sh
aws ec2 create-volume --size 1 --availability-zone us-east-1a
{
  "AvailabilityZone": "us-east-1a",
  "Tags": [],
  "Encrypted": false,
  "VolumeType": "gp2",
  "VolumeId": "vol-1234567890abcdef0",
  "State": "creating",
  "Iops": 240,
  "SnapshotId": "",
  "CreateTime": "YYYY-MM-DDTHH:MM:SS.000Z",
  "Size": 80
}
```
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mongodb
spec:
  volumes:
  - name: mongodb-data
    awsElasticBlockStore:
    volumeId: vol-1234567890abcdef0
      fsType: ext4
  containers:
  - ...
```

### 4.3 NFS Volume
如果选择自己搭建k8s cluster, 也可以自己配置persistent storage. 例如, 自己搭建一个NFS服务器, 并将NFS服务器上的某个文件夹mount到pod中:
```yaml
...
spec:
  volumes:
    - name: mongodb-data
      nfs:
        server: 1.2.3.4
        path: /some/path 
```
除此之外, k8s还支持其他persistent storage:
* iscsi: ISCSI disk
* glusterfs: GlusterFS Mount
* rbd: RADOS Block Device
* flexVolume: 自定义驱动的存储
* cinder: Cinder block storage device
* cephfs: Ceph File System
* flocker: Flocker container data management platform
* fc: Fibre Channel storage device


## 5. Decouple Pods from the Underlying Storage Technology
上述所有volume都解决了persistent storage问题, 但每一个volume都与平台或底层技术绑定. 以GCE persistent disk为例, 若开发者决定将k8s cluster从GCP迁移到AWS, 则需重写每一个pod. 因此需要一种方法, 既提供persistent storage, 又不绑定某个云服务提供商或存储技术. 理想状态下, 开发者不需要了解每个volume的底层配置, 所有volume的配置应由cluster管理员负责. K8s为此提供PV(**PersistentVolume**)和PVC(**PersistentVolumeClaim**)来方便volume的配置与管理.
简单来说, PV是对存储资源的一种抽象, 通常由cluster管理员手动或自动创建; PVC则是pod对存储资源的请求声明, 从而分离存储资源的申请和使用: 
* cluster将存储资源包装成一个PV
* 开发者在PVC中说明所需的存储大小和访问模式, k8s会找到最合适的PV并将绑定给该PVC

![PersistentVolumes are provisioned by cluster admins and consumed by pods through PersistentVolumeClaims](/images/Kubernetes/vol-5-1.png)

### 5.1 Claim a PersistentVolume
以GCP为例, cluster管理员需要创建一个PV, 其存储依赖于GCE persistent disk:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongodb-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  - ReadOnlyMany
  persistentVolumeReclaimPolicy: Retain
  gcePersistentDisk:
    pdName: mongodb
    fsType: ext4 
```
该PV的配置如下:
* PV的存储空间为1Gb
* 由于`persistentVolumeReclaimPolicy`为`Retain`, 因此即便PVC解绑该PV, 该PV也不会被删除
* `gcePersistentDisk`的配置与之前相同

```sh
$ kubectl get pv
NAME       CAPACITY RECLAIMPOLICY ACCESSMODES STATUS    CLAIM
mongodb-pv 1Gi      Retain        RWO,ROX     Available 
```
由于新创建的PV还未与任何PVC绑定, 因此`mongodb-pv`的状态为`Available`, 而不是`Bound`. PV不属于某个namespace, 只与cluster绑定, 但PVC必须属于某个namespace, 只有pod与PVC处于同一namespace时才能在pod中使用PVC.
![PV doesn’t belong to any namespace, unlike pods and PVC](/images/Kubernetes/vol-5-2.png)

### 5.2 Claiming a PersistentVolume by creating a PersistentVolumeClaim
假设开发者需要一个1Gb大小的persistent storage, 可创建一个PVC资源:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  resources:
    requests:
      storage: 1Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: ""
```
K8s会为该PVC寻找一个合适的PV:
* PV的存储大小必须大于PVC的存储需求
* PV的访问模式必须满足PVC的访问需求

通过以下命令可显示所有PVC:
```sh
$ kubectl get pvc
NAME        STATUS VOLUME     CAPACITY ACCESSMODES AGE
mongodb-pvc Bound  mongodb-pv 1Gi      RWO,ROX     3s
```
K8s为存储空间提供了三种访问模式:
1. RWO(ReadWriteOnce): 只允许一个node读取或写入该存储资源
2. ROX(ReadOnlyMany): 允许多个node读取该存储资源
3. RWX(ReadWriteMany): 允许多个node读取或写入该存储资源

需要注意的是, 上述访问模式与node的数量有关, 不与pod数量相关. 以下是`mongodb-pv`与PVC绑定后的状态:
```sh
$ kubectl get pv
NAME       CAPACITY ACCESSMODES STATUS CLAIM               AGE
mongodb-pv 1Gi      RWO,ROX     Bound  default/mongodb-pvc 1m
```

### 5.3 Use a PersistentVolumeClaim
PVC与PV绑定后就可以在pod中使用PVC:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mongodb
spec:
  containers:
  - image: mongo
    name: mongodb
    volumeMounts:
    - name: mongodb-data
      mountPath: /data/db
    ports:
    - containerPort: 27017
      protocol: TCP
  volumes:
  - name: mongodb-data
    persistentVolumeClaim:
    claimName: mongodb-pvc 
```
虽然需要一些额外步骤来使用PVC和PV, 但开发者从此不必知道volume的底层技术和存储位置, 管理员将volume转移到其他平台或使用其他技术时也不必通知开发者.
![PV doesn’t belong to any namespace, unlike pods and PVC](/images/Kubernetes/vol-5-3.png)

### 5.4 Recycle PersistentVolume
删除PVC后, PV的状态会从`Bound`变为`Released`, 而不是`Available`. 若新的PVC尝试绑定该PV, 该PVC的状态会一直为`Pending`. K8s之所以不允许PV重新绑定, 是为了保证PV中的数据得到合适的处理(清理或再利用):
```sh
$ kubectl delete pod mongodb
pod "mongodb" deleted
$ kubectl delete pvc mongodb-pvc
persistentvolumeclaim "mongodb-pvc" deleted

$ kubectl get pv
NAME       CAPACITY ACCESSMODES STATUS   CLAIM               REASON AGE
mongodb-pv 1Gi      RWO,ROX     Released default/mongodb-pvc        5m
```
两种回收PV的方式:
* 手动回收: 将`persistentVolumeReclaimPolicy`设为`Retain`后, PV只能被删除后重新创建才能与新的PVC绑定
* 自动回收: 将`persistentVolumeReclaimPolicy`设为`Recycle`或`Delete`, PV与PVC解绑后自动变为`Available`状态. `Recycle`表示PV将保留数据, `Delete`表示PV将删除所有数据.
  ![PV doesn’t belong to any namespace, unlike pods and PVC](/images/Kubernetes/vol-5-4.png)


## 6. Dynamic Provisioning of PersistentVolume
PV和PVC让存储资源的申请和获取分离. 开发者只需在PVC中说明所需存储空间和访问模式即可获取存储资源; 但cluster管理员面临一个难题: 随着cluster中的pod数量不断增加, 其申请的存储资源也越来越多, 需要cluster管理员不断创建PV. K8s为此提供了**StorageClass**来实现对PV的动态供给. StorageClass会根据不同的PVC创建对应的PV, 因此cluster管理员不必手动创建每个PV. StorageClass与PV相同, 都不属于某个namespace, 只属于cluster.

### 6.1 Define a StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  zone: europe-west1-b 
```
上述YAML文件创建了一个StorageClass, 其包含一个provisioner, 负责生成PV. K8s内置了绝大多数云服务提供商的provisioner, cluster管理员也可以自定义provisioner. 本例中使用GCE的persistent disk provisioner, 每当PVC需要PV时, provisioner会创建一个符合要求的PV.

### 6.2 Request the StorageClass in a PersistentVolumeClaim
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  storageClassName: fast
  resources:
    requests:
      storage: 100Mi
  accessModes:
  - ReadWriteOnce
```
运行`kubectl get pvc`时可看到, StorageClass自动创建了一个名为`pvc-1e6bc048`的PV, 且PVC成功与该PV绑定:
```sh
$ kubectl get pvc mongodb-pvc
NAME        STATUS VOLUME       CAPACITY ACCESSMODES STORAGECLASS
mongodb-pvc Bound  pvc-1e6bc048 1Gi      RWO         fast

$ kubectl get pv
NAME         CAPACITY ACCESSMODES RECLAIMPOLICY STATUS  STORAGECLASS
pvc-1e6bc048 1Gi      RWO         Delete        Bound   fast
```
StorageClass不仅自动生成了PV, 还在GCP中自动申请persistent disk.
```sh
$ gcloud compute disks list
NAME                        ZONE           SIZE_GB TYPE        STATUS
gke-kubia-dyn-pvc-1e6bc048  europe-west1-d 1       pd-ssd      READY
gke-kubia-default-pool-71df europe-west1-d 100     pd-standard READY
gke-kubia-default-pool-79cd europe-west1-d 100     pd-standard READY
gke-kubia-default-pool-blc4 europe-west1-d 100     pd-standard READY
mongodb                     europe-west1-d 1       pd-standard READY
```
除了帮助cluster管理员摆脱重复创建PV的繁琐工作, StorageClass还可以实现PVC的跨cluster: 只要所有cluser上都部署相同的StorageClass, 那么就可以在所有cluster中使用相同PVC.

### 6.3 Dynamic provisioning without specifying a StorageClass
除了自定义的StorageClass, GKE还提供了默认StorageClass:
```sh
$ kubectl get sc
NAME               TYPE
fast               kubernetes.io/gce-pd
standard (default) kubernetes.io/gce-pd
```
GKE中, 默认StorageClass名为`standard`. 若PVC没有指定任何StorageClass, 将会使用该StorageClass. 
```sh
$ kubectl get sc standard -o yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.beta.kubernetes.io/is-default-class: "true"
  creationTimestamp: 2017-05-16T15:24:11Z
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
    kubernetes.io/cluster-service: "true"
  name: standard
  resourceVersion: "180"
  selfLink: /apis/storage.k8s.io/v1/storageclassesstandard
  uid: b6498511-3a4b-11e7-ba2c-42010a840014
parameters:
  type: pd-standard
provisioner: kubernetes.io/gce-pd 
```
需要注意的是, 不同云计算平台上的默认StorageClass可能拥有不同的provisioner, GKE使用`kubernetes.io/gce-pd`.

总结一下, PV/PVC模式下的volume分为两种:
* pre-provisioned PV: cluster管理员创建PV, k8s根据PVC的存储需求匹配一个合适的PV
* dynamic provisioning PV: cluster管理员创建StorageClass, StorageClass根据PVC的存储需求创建一个合适的PV

使用pre-provisioned PV时, 需要在PVC中标注`storageClassName: ""`, 这样k8s就不会使用StorageClass, 而去寻找合适的PV.
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
...
spec:
  ...
  storageClassName: ""
```

以下为dynamically provisoneing PV的流程图:
![The complete picture of dynamic provisioning of PersistentVolumes](/images/Kubernetes/vol-6-1.png)
