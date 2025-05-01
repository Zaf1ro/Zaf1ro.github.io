---
title: Access Pod Metadata
category:
  - K8s
tag:
  - K8s
abbrlink: a0f1
date: 2019-11-03 09:54:49
keywords:
description:
---

## 1. Pass Metadata through the Downward API
当container想要获取pod的metadata时, 可将metadata写入configMap/secret中, 但这种方式存在很多问题:
* 修改pod配置时, 需同步更新configMap/secret
* 某些metadata只有在pod创建时才能获取, 如pod的IP地址, pod何时被ReplicaSet创建, 但pod创建后无法修改configMap/secret
* 某些metadata已经存在于pod的资源清单(manifest file)中, 如label或annotation, 需将这些信息重新写入configMap/secret中

为解决上述问题, k8s提供**Downward API**让pod中的container可直接获取pod的metadata. Downward API并不是一个REST API, 它会将指定的metadata导入**环境变量**或**volume**中.  
![The Downward API exposes pod metadata through environment variables or files](/images/Kubernetes/metadata-1-1.png)

以下是Downward API包含的pod metadata:
* pod的名字
* pod的IP地址
* pod所属的namespace
* pod所在的worker node名字
* pod所属的service名字
* 每个container的requested CPU/memory
* 每个container的CPU/memory limit
* pod的label
* pod的annotation

以下是request CPU/memory和CPU/memory limit的区别:
* Requested CPU/memory: 表示该container申请的资源数量, 但并不意味着container一定拥有这些资源. 例如, 一个container申请200mb内存, 但只使用100mb内存, 那么剩下的100mb会在其他container的需求超出其请求资源时借给其他container.
* CPU/memory limit: 表示该container的资源上限, 当一个container获取的资源超出该值时, 会被强制终止

总结一下, **CPU/memory limit**等于**requested CPU/memory**加上**从其他container借来的CPU/memory**. requested CPU/memory表示container通常情况下需要多少资源, CPU/memory limit表示container可拥有的最大资源量.

上述大部分metadata都可通过**环境变量**或**volume**获取, 但label和annotation只能通过**volume**获取, 因为:
* label或annotation通常包含一个或多个键值对, 无法放入单个环境变量
* label或annotation可在pod运行时被修改, 而环境变量一旦初始化则无法修改

### 1.1 Expose Metadata through Environment Variables
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downward
spec:
  containers:
  - name: main
    image: busybox
    command: ["sleep", "9999999"]
    resources:
      requests:
        cpu: 15m
        memory: 100Ki
      limits:
        cpu: 100m
        memory: 4Mi
  env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
  - name: POD_IP
    valueFrom:
      fieldRef:
        fieldPath: status.podIP
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: SERVICE_ACCOUNT
    valueFrom:
      fieldRef:
        fieldPath: spec.serviceAccountName
  - name: CONTAINER_CPU_REQUEST_MILLICORES
    valueFrom:
      resourceFieldRef:
        resource: requests.cpu
        divisor: 1m
  - name: CONTAINER_MEMORY_LIMIT_KIBIBYTES
    valueFrom:
      resourceFieldRef:
        resource: limits.memory
        divisor: 1Ki
```

![Pod metadata and attributes can be exposed to the pod through environment variables](/images/Kubernetes/metadata-1-2.png)

上述YAML文件中将pod的metadata放入环境变量. 其中, requested CPU/memory和CPU/memory limit需标注一个额外参数**divisor**, 其表示资源单位:
* CPU的单位为**millicore**, 表示千分之一的CPU单元(CPU core). 本例中, divisor为1m, 环境变量中`CONTAINER_CPU_REQUEST_MILLICORES`为15, 表示该container请求了1.5%的CPU
* Memory的单位为**Kibibtye**, 表示一千字节. 本例中, divisor为1Ki, 环境变量中`CONTAINER_MEMORY_LIMIT_KIBIBYTES`为4096, 表示该container的内存上限为4Mi.

进入pod可查看环境变量:
```sh
$ kubectl exec downward env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=downward
CONTAINER_MEMORY_LIMIT_KIBIBYTES=4096
POD_NAME=downward
POD_NAMESPACE=default
POD_IP=10.0.0.10
NODE_NAME=gke-kubia-default-pool-32a2cac8-sgl7
SERVICE_ACCOUNT=default
CONTAINER_CPU_REQUEST_MILLICORES=15
KUBERNETES_SERVICE_HOST=10.3.240.1
KUBERNETES_SERVICE_PORT=443
...
```

### 1.2 Pass Metadata through Files in a DownwardAPU Volume
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downward
  labels:
    foo: bar
  annotations:
    key1: value1
    key2: |
      multi
      line
      value
spec:
  containers:
  - name: main
    image: busybox
    command: ["sleep", "9999999"]
    resources:
      requests:
        cpu: 15m
        memory: 100Ki
      limits:
        cpu: 100m
        memory: 4Mi
    volumeMounts:
    - name: downward
      mountPath: /etc/downward
  volumes:
  - name: downward
    downwardAPI:
      items:
      - path: "podName"
        fieldRef:
          fieldPath: metadata.name
      - path: "podNamespace"
        fieldRef:
          fieldPath: metadata.namespace
      - path: "labels"
        fieldRef:
          fieldPath: metadata.labels
      - path: "annotations"
        fieldRef:
          fieldPath: metadata.annotations
      - path: "containerCpuRequestMilliCores"
        resourceFieldRef:
          containerName: main
          resource: requests.cpu
          divisor: 1m
      - path: "containerMemoryLimitBytes"
        resourceFieldRef:
          containerName: main
          resource: limits.memory
          divisor: 1
```
上述YAML文件将metadata挂靠在`/etc/downward`下. 如下图:
![Use a downwardAPI volume to pass metadata to the container](/images/Kubernetes/metadata-1-3.png)

需要注意的是, 当在volume中使用requested CPU/memory或CPU/memory limit时, 需标注container名字, 因为每个container有不同的request和limit.


## 2. Kubernetes API Server
Downward API虽然能为container提供当前pod的metadata, 但若container需要访问pod之外的信息, 可通过环境变量获取service相关的信息, 但如果是其他信息, 则只能需要访问K8s API server.

![Talking to the API server from inside a pod to get information about other API objects](/images/Kubernetes/metadata-2-1.png)

### 2.1 Explore the Kubernetes REST API
向k8s API发送请求前需要先了解这套API:
```sh
$ kubectl cluster-info
Kubernetes master is running at https://192.168.99.100:8443
```
由于API server使用**HTTPS**, 因此无法直接访问:
* 访问前进行HTTPS认证
* 使用kubectl proxy命令启动一个proxy server, 由于proxy server接受HTTP连接, 因此container可借助proxy server与API server通信

```sh
$ kubectl proxy
Starting to serve on 127.0.0.1:8001
```
该命令会自动获取所有需要的信息(API server URL, authorization token等). Proxy server监听8001端口.
```sh
$ curl http://localhost:8001
{
  "paths": [
  "/api",
  "/api/v1",
  "/apis",
  "/apis/apps",
  "/apis/apps/v1beta1",
  ...
  "/apis/batch",
  "/apis/batch/v1",
  "/apis/batch/v2alpha1",
  ...
```
上述每一行都是一个**API group**, 每一个API Group关联一个或多个k8s resource. API group可分为以下两类:
* core group: 包含一些核心资源, 如pod, node, namespace, service, secret, volume, configMap等, URL路径为/`api/v1`, 对应manifest中的`apiVersion: v1`
* named groups: 包含一些K8s的拓展功能, URL路径为`/apis/<GROUP_NAME\>/<VERSION>`, :、对应manifest中的`apiVersion: GROUP_NAME/VERSION`

以下是named group的一些例子:
* /apis/apps: Deployment, ReplicaSet, StatefulSet, DaemonSet
* /apis/extensions: Ingress, NetworkPolicies, PodSecurityPolicies
* /apis/batch: Job, CronJob
* /apis/storage.k8s.io: StorageClass, VolumeAttachment
* /apis/policy: PodDisruptionBudget

以Job为例, 其位于`/api/batch`的路径上:
```sh
$ curl http://localhost:8001/apis/batch
{
  "kind": "APIGroup",
  "apiVersion": "v1",
  "name": "batch",
  "versions": [
    {
      "groupVersion": "batch/v1",
      "version": "v1"
    },
    {
      "groupVersion": "batch/v2alpha1",
      "version": "v2alpha1"
    }
  ],
  "preferredVersion": {
    "groupVersion": "batch/v1",
    "version": "v1"
  },
  "serverAddressByClientCIDRs": null
}
```
上述为batch API group的描述, 包括version和其他信息. 以下是/api/batch/v1的路径访问结果:
```sh
$ curl http://localhost:8001/apis/batch/v1
{
  "kind": "APIResourceList",
  "apiVersion": "v1",
  "groupVersion": "batch/v1",
  "resources": [
    {
      "name": "jobs",
      "namespaced": true,
      "kind": "Job",
      "verbs": [
        "create",
        "delete",
        "deletecollection",
        "get",
        "list",
        "patch",
        "update",
        "watch"
      ]
    },
    {
      "name": "jobs/status",
      "namespaced": true,
      "kind": "Job",
      "verbs":
        "get",
        "patch",
        "update"
      ]
    }
  ]
}
```
`name`表示可访问的路径, `kind`表示所属resource类型, `namespaced`表示该资源为全局资源或仅限于某个namespace, `verbs`表示可进行的操作类别, 以下是所有操作类别与其对应的HTTP方法:
* create: 创建一个resource object, 如`POST /resourceURL`
* update: 更新已有resource object, 如`PUT /resourceURL/name`
* patch: 部分更新已有resource object, 如`PATCH /resourceURL/name`
* get: 获取特定resource object, 如`GET /resourceURL/name`
* list: 获得所有符合selector规则的resource object集合, 如G`ET /resourceURL`
* watch: 监视某个resource object或某个resource object集合, 如G`ET /resourceURL?watch=true`
* delete: 删除某个resource object, 如`DELETE /resourceURL/name`
* deletecollection: 删除某个resource object集合, 如`DELETE /resourceURL`


向/apis/batch/v1/jobs发送GET请求可获得当前cluster中所有job:
```sh
$ curl http://localhost:8001/apis/batch/v1/jobs
{
  "kind": "JobList",
  "apiVersion": "batch/v1",
  "metadata": {
    "selfLink": "/apis/batch/v1/jobs",
    "resourceVersion": "225162"
  },
  "items": [
    {
      "metadata": {
        "name": "my-job",
        "namespace": "default",
        ...
```
也可通过namespace和job名称获取该job的详细信息:
```sh
$ curl http://localhost:8001/apis/batch/v1/namespaces/default/jobs/my-job
{
  "kind": "Job",
  "apiVersion": "batch/v1",
  "metadata": {
    "name": "my-job",
    "namespace": "default",
    ...
```
可以发现, 上述输出与执行kubectl get job my-job -o json的结果相同.

### 2.2 Access the APi Server from within a Pod
上述与API server沟通的方式仅限于node中, 由于container中无法调用kubectl, 因此无法创建proxy server.  若想要在container中与API server通讯, 需满足以下三个条件:
* 获取API server的IP address
* 保证对方为API server, 而不是其他人
* 与API server进行身份验证, 否则API server不会处理任何请求

为展示整个流程, 我们可运行一个不执行任何操作的pod, 其已包含curl程序, 以下是该pod的manifest:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: curl
spec:
  containers:
  - name: main
    image: tutum/curl
    command: ["sleep", "9999999"]
```
执行`kubectl exec -it curl bash`可在container中执行一个bash shell. 首先我们需要获取API server的IP地址, k8s会在`default`的namespace中自动启动一个service, 名为**kubernetes**, 其包含API server的IP地址和端口号:
```sh
$ kubectl get svc
NAME        CLUSTER-IP  EXTERNAL-IP PORT(S) AGE
kubernetes  10.0.0.1    <none>      443/TCP 46d
```

container的环境变量也包含API server的IP地址和端口号:
```sh
root@curl:/# env | grep KUBERNETES_SERVICE
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_HOST=10.0.0.1
KUBERNETES_SERVICE_PORT_HTTPS=443
```

实际上我们不需要知道API server的IP地址和端口号, 直接访问`https://kubernetes`即可:
```sh
root@curl:/# curl https://kubernetes
curl: (60) SSL certificate problem: unable to get local issuer certificate
...
If you'd like to turn off curl's verification of the certificate, use
 the -k (or --insecure) option.
```

接下来需要验证API server身份: k8s集群中每个container都默认挂载一个secret, 挂载在`/var/run/secrets/kubernetes.io/serviceaccount/`:
```sh
root@curl:/# ls /var/run/secrets/kubernetes.io/serviceaccount/
ca.crt namespace token
```

* ca.crt: CA证书, 用于验证其他证书
* namespace: 当前pod所在的namespace名称
* token: 用于向API server进行身份验证

使用ca.crt连接API server:
```sh
root@curl:/# curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://kubernetes
Unauthorized
```
curl成功验证了API server的身份, 但curl并没有向API server进行身份验证, 因此需要在请求加入token:
```sh
root@curl:/# TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
root@curl:/# curl -H "Authorization: Bearer $TOKEN" https://kubernetes
{
  "paths": [
    "/api",
    "/api/v1",
    "/apis",
    "/apis/apps",
    "/apis/apps/v1beta1",
    "/apis/authorization.k8s.io",
    ...
    "/ui/",
    "/version"
  ]
}
```
自此container与API server成功建立连接, 当container向API server查询或修改某个资源时, 需要标注namespace, 因此可将secret volume中**namespace**文件导入到环境变量中:
```sh
root@curl:/# NS=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
root@curl:/# curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/$NS/pods
{
  "kind": "PodList",
  "apiVersion": "v1",
  ...
```
整个流程如下图:
![Use the files from the default-token Secret to talk to the API server](/images/Kubernetes/metadata-2-2.png)

### 2.3 Simplify API Server Communication with Ambassador Container
上述步骤虽然实现了container与API server通信, 但操作过于复杂, 因此可使用Sidecar Pattern: 运行一个**ambassador container**作为代理, 作为container与API server的中间代理.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: curl-with-ambassador
spec:
  containers:
  - name: main
    image: tutum/curl
    command: ["sleep", "9999999"]
  - name: ambassador
    image: luksa/kubectl-proxy:1.6.2 
```
上述YAML文件创建了一个pod, 其包含两个container: 主程序main和代理程序ambassador. Ambassador接收请求并转发给API server, 这样main不需要配置任何certificate和token.

![Offload encryption, authentication, and server verification in an ambassador container](/images/Kubernetes/metadata-2-3.png)

### 2.4 Use Client Libraries to Talk to the API Server
除了ambassador, K8s官方还为以下两种语言提供了API Client Libraries:
* Golang client—https://github.com/kubernetes/client-go
* Python—https://github.com/kubernetes-incubator/client-python

以下为其他语言的API Client Libraries:
* Java client by Fabric8—https://github.com/fabric8io/kubernetes-client
* Node.js client by tenxcloud—https://github.com/tenxcloud/node-kubernetes-client
* PHP—https://github.com/devstub/kubernetes-api-php-client
* Ruby—https://github.com/Ch00k/kubr
* Clojure—https://github.com/yanatan16/clj-kubernetes-api
* Scala—https://github.com/doriordan/skuber
* Perl—https://metacpan.org/pod/Net::Kubernetes
