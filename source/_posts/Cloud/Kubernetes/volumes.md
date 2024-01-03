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
Volume并不是Kubernetes的一种resource, 而是作为Pod specification中的一个组成部分. Volume无法用单独的YAML创建, 且只有volume被mount到特定的container上才可以被其访问.
例如: Pod中有三个container, 分别为:
1. WebServer: 利用**/var/htdocs/**下的HTML文件生成网页, 将log放入**/var/logs/**中
2. ContentAgent: 生成HTML文件并保存到**/var/html/**中
3. LogRotator: 处理**/var/logs/**下的日志文件

若不使用volume, 则每个container所拥有的filesystem各自独立, 如下:
![Three containers of the same pod without shared storage](/images/Kubernetes/vol-1.png)

但当使用volume后, container可以通过volume互通filesystem, 如下:
![Three containers sharing two volumes mounted at various mount paths](/images/Kubernetes/vol-2.png)

Kubernetes提供了多种volume类型, 以下是所有可用的volume类型:
* emptyDir: 生成一个空文件夹用于存放临时数据
* hostPath: mount到Pod所处的worker node的filesystem上
* gitRepo: 利用Git repository初始化volume
* nfs: mount到一个NFS(Network File System)上
* gcePersistentDisk, awsElasticBlockStore, azureDisk: mount到云服务提供商特定的存储服务
* cinder, cephfs, iscsi, flocker, glusterfs, quobyte, rbd, flexVolume, vsphereVolume, photonPersistentDisk, scaleIO: mount到其他类型的网络存储服务
* configMap, secret, downwardAPI: 特殊类型的volume, 用于提供Kubernetes和cluster所拥有的的信息
* persistentVolumeClaim: 使用pre-provisioned或dynamically provisioned persistent stroage



## 2. Use Volumes to Share Data between Containers
### 2.1 emptyDir Volume
emptyDir是最简单的volume类型, container可通过emptyDir来共享文件. 但缺陷也很多: emptyDir生存周期与Pod相同, Pod被删除后emptyDir也会消失. 以下是emptyDir的例子, mountPath为container需要mount的文件目录:
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
上述YAML文件创建了一个Pod, 共包含:
* 两个container: html-generator用于创建HTML文件并保存到**/var/htdocs**, web-server用于从**/usr/share/nginx/html**目录中读取HTML文件并生成网页.
* 一个volume: 名为html, 用于连接html-generator的**/var/htdocs**与web-server的**/usr/share/nginx/html**

emptyDir默认将数据保存在worker node的filesystem, Kubernetes让用户可以修改emptyDir的存储媒介:
```yaml
volumes:
- name: html
  emptyDir:
  medium: Memory
```

### 2.2 gitRepo Volume
gitRepo作为emptyDir的增强版, 会先创建一个空volume, 则从Git repository复制数据, 整个流程如下:
![A gitRepo volume is an emptyDir volume initially populated with the contents of a Git repository](/images/Kubernetes/vol-3.png)

gitRepo volume被创建后, volume会断开与Git repository的同步. 即使远程Git repository被修改, volume中的数据也不会修改. 以下gitRepo volume的例子:
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
上述YAML文件创建了一个Pod, 共包含:
* 一个container: web-server用于从**/usr/share/nginx/html**中读取HTML文件并生成网页
* 一个volume: 名为html的gitRepo volume用于从Git repository复制数据

虽然gitRepo volume不提供同步功能, 但Docker Hub上有很多container image来实现该功能. 这种container也被称为sidecar container, 虽然与web-server container处于同一Pod, 但却为辅助web-server运行而存在.
gitRepo还存在一个缺陷: 不支持从private Git repository中复制数据, 因为private Git repository需要SSH protocol和其他配置文件. 如果需要从private Gitrepository复制数据, 还需要其他sidebar container的帮助. 生存周期方面, gitRepo与emptyDir, 都无法实现数据持久化.



## 3. Access Files on the Worker Node's Filesystem
大部分Pod游离在多个worker node中运行, 所以将Pod的数据不应保存在worker node的file system上. 但有些Pod(例如: DaemonSet)会绑定在worker node上, 因此可以将数据保存在worker node的file system. Kubernetes提供了hostPath volume将container的文件目录mount到worker node上的filesystem, 如下:
![A hostPath volume mounts a file or directory on the worker node into the container’s filesystem](/images/Kubernetes/vol-4.png)

下面YAML文件创造了一个Pod, 其中test-container会将**/test-pd** mount到worker node的**/data**文件夹. 添加修改或删除container中**/test-pd**内文件都会同步到worker node上的**/data**, 反之同理.
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
hostPath相对于emptyDir和gitRepo提供了persistent storage. 当Pod被移除后数据不会消失, 只要Pod再次被部署到该worker node, 就可以恢复数据. 缺陷也很明显, Pod一旦被重新部署到其他worker node, 则数据全部丢失.



## 4. Persistent Storage
若Pod需要persistent data, 但又随时会被重新分配到不同的worker node上, 则以上所有Volume都不可用. . 不同的cloud infrastructure platform提供了不同的NAS(network-attached sotrage)方法来解决该问题. 以下会在GCP(Google Cloud Platform)和AWS(Amazon Web Services)上分别部署mongoDB.

### 4.1 GCP Persistent Disk
GCP提供自家的persistent disk. NAS不属于某个namespace, 也不与cluster绑定, 只属于某个zone. cluster与NAS必须处于某个zone, 可运行gcloud命令来查看当前所有cluster所在的zone:
```sh
$ gcloud container clusters list
NAME  ZONE           MASTER_VERSION MASTER_IP ...
kubia europe-west1-b 1.2.5          104.155.84.137 ...
```
从上述命令可知, kubia位于europe-west1-b:
```sh
$ gcloud compute disks create --size=1GiB --zone=europe-west1-b mongodb
NAME    ZONE           SIZE_GB TYPE        STATUS
mongodb europe-west1-b 1       pd-standard READY
```
上述命令在europe-west1-b zone创造了一个1Gb空间的NAS, 现在可创造Pod来使用该NAS:
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
通过在volumes中标注gcePersistentDisk可将该Pod与GCP persistent disk绑定, 即使该Pod被移除或重新分配到其他worker node, 其数据也会被保留下来. 如下图:
![A pod with a single container running MongoDB, which mounts a volume referencing an external GCE Persistent Disk](/images/Kubernetes/vol-5.png)

### 4.2 AWS Persistent Data
AWS和Azure也提供了相同的NAS, 步骤与GCP的NAS相同: 在cluster所在的zone中创建volume, 再在Pod的YAML文件中使用该volume:
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
除了使用cloud infrastructure platform提供了NAS之外, 还可以自己搭建NFS server来提供NAS, 只需要标记NFS server的IP地址和暴露的路径即可:
```yaml
...
spec:
  volumes:
    - name: mongodb-data
      nfs:
        server: 1.2.3.4
        path: /some/path 
```



## 5. Decouple Pods from the Underlying Storage Technology
上述Volume虽然解决了大部分persistent data问题, 但需要developer在部署应用到cloud的同时了解Kubernetes提供的底层volume知识. 但理想状态下, developer并不需要知道这些volume的配置与区别, 这些volume的配置应由cluster administrator来管理. Kubernetes为此提供PV(PersistentVolume)和PVC(PersistentVolumeClaim)来方便Volume的配置与管理.
简单来说, PV是对Kubernetes存储资源的一种抽象, 可手动或由Kubernetes自动创建; PVC则是需要存储资源的User(如Pod)对存储资源的请求声明. 这样存储资源被分割为两部分: cluster administrator使用PV预先分配存储资源; developer根据应用所需存储资源大小来决定使用哪个PVC, PVC会绑定最合适的PV从而获取存储资源, 如下图:
![PersistentVolumes are provisioned by cluster admins and consumed by pods through PersistentVolumeClaims](/images/Kubernetes/vol-6.png)

### 5.1 Claim a PersistentVolume
以GCP Persistent Disk为例, cluster administrator需要为developer提供PV:
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
以上PV以GCP的Persistent Disk作为存储资源提供者, 每次绑定PV都会获得1Gb的存储资源, 将persistentVolumeReclaimPolicy设置为**Retain**可保证PV被解绑后也会保留数据. 可调用**kubectl get pv**来获取所有PV:
```sh
$ kubectl get pv
NAME       CAPACITY RECLAIMPOLICY ACCESSMODES STATUS    CLAIM
mongodb-pv 1Gi      Retain        RWO,ROX     Available 
```
由于还未创建PVC, 所以mongodb-pv为**Available**而不是**
Bound**. PV不属于某个namespace, 只与cluster绑定; 但PVC有特定的namespace范围. 

### 5.2 Claim a PersistentVolumeClaim
以下PVC会去寻找存储空间至少为1Gb的PV并与其绑定, 其PV必须支持ReadWriteOnce的访问模式:
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
通过以下命令可显示所有cluster的PVC:
```sh
$ kubectl get pvc
NAME        STATUS VOLUME     CAPACITY ACCESSMODES AGE
mongodb-pvc Bound  mongodb-pv 1Gi      RWO,ROX     3s
```
Kubernetes为存储空间提供了三种访问模式:
1. RWO(ReadWriteOnce): 只有一个node可读取或写入该存储资源
2. ROX(ReadOnlyMany): 可有多个node读取该存储资源
3. RWX(ReadWriteMany): 可有多个node读取或写入该存储资源

PVC被创建后会自动寻找符合条件的PV, 以下是mongodb-pv的最新状态:
```sh
$ kubectl get pv
NAME       CAPACITY ACCESSMODES STATUS CLAIM               AGE
mongodb-pv 1Gi      RWO,ROX     Bound  default/mongodb-pvc 1m
```

### 5.3 Use a PersistentVolumeClaim
创建完毕PVC后就可以在Pod中使用PVC来获取存储资源:
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
整个使用的流程如下图:
![PV doesn’t belong to any namespace, unlike PVC](/images/Kubernetes/vol-7.png)

### 5.4 Recycle PersistentVolume
当PV所绑定的PVC和Pod被删除后, PV的状态会从**Bound**切换为**Released**, 而不是**Available**, 此时的PV不能被新的PVC所绑定. Kubernetes之所以不允许立刻绑定新的PVC, 是为了保证PV中的数据得到合适的处理(清理或再利用):
```sh
$ kubectl delete pod mongodb
pod "mongodb" deleted
$ kubectl delete pvc mongodb-pvc
persistentvolumeclaim "mongodb-pvc" deleted

$ kubectl get pv
NAME       CAPACITY ACCESSMODES STATUS   CLAIM               REASON AGE
mongodb-pv 1Gi      RWO,ROX     Released default/mongodb-pvc        5m
```
有两种回收PV的方式:
1. 手动回收: 将persistentVolumeReclaimPolicy设为Retain后, PV只能被删除后重新创建才能与新的PVC绑定
2. 自动回收: 将persistentVolumeReclaimPolicy设为Recycle或Delete后, PV在与PVC解绑后会自动变为**Available**状态. Recycle表示PV保留原有数据; Delete表示PV所有数据会被删除.



## 6. Dynamic Provisioning of PersistentVolume
PV和PVC让存储资源的获取步骤分离. developer只需创建PVC即可获取存储资源, 而不需了解存储资源的细节. 但cluster administrator面临一个难题: 随着cluster中Pod越来越多, 申请存储资源的PVC也越来越多时, 需要创建更多PV来满足请求, 这使得cluster administrator的工作量增大. Kubernetes为此提供了StorageClass来实现对PV的动态供给.
StorageClass会根据PVC的请求不断创建PV, 因此无需再创建任何PV. StorageClass与PV相同, 都不与namespace绑定, 只属于单个cluster. 

### 6.1 Define a StorageClass
以GCP为例, 可创建StorageClass并使用GCP Persistent Disk作为底层存储资源自动为PVC创建相应PV:
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
当运行kubectl get pvc时可看到PVC已自动绑定StorageClass且StorageClass为PVC创建了临时PV:
```sh
$ kubectl get pvc mongodb-pvc
NAME        STATUS VOLUME       CAPACITY ACCESSMODES STORAGECLASS
mongodb-pvc Bound  pvc-1e6bc048 1Gi      RWO         fast

$ kubectl get pv
NAME         CAPACITY ACCESSMODES RECLAIMPOLICY STATUS  STORAGECLASS
pvc-1e6bc048 1Gi      RWO         Delete        Bound   fast
```

### 6.3 Dynamic provisioning without specifying a StorageClass
对于大多数cloud infrastructure platform来说, 其Kubernetes都自带provisioner. 通过调用**kubectl get sc**可获取所有的StorageClass:
```sh
$ kubectl get sc
NAME               TYPE
fast               kubernetes.io/gce-pd
standard (default) kubernetes.io/gce-pd
```
GCP提供一个默认StorageClass名为**standard**, 当PVC没有指定任何StorageClass时, 将会使用其作为StorageClass. 
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
**storageclass.beta.kubernetes.io/is-default-class**表示该StorageClass是否为默认选项. 若不想使用任何StorageClass, 则在PVC YAML文件中标注StorageClass为空:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
...
spec:
  ...
  storageClassName: ""
```
以下是整个Dynamically Provisoned PersistentVolume的使用步骤:
![The complete picture of dynamic provisioning of PersistentVolumes](/images/Kubernetes/vol-8.png)
