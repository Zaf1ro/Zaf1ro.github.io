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
Kubernetes提供Downward API让container中的application获取Pod metadata. 当然, 用户也可以将这些信息写入ConfigMap或Secret Volume中, 但每次都创建一个ConfigMap或Secret并与Pod绑定. Downward API会自动包含所需要的Pod metadata, 可直接从DownwardAPI volume或environment variables中获取, 如下图:
![The Downward API exposes pod metadata through environment variables or files](/images/Kubernetes/metadata-1.png)

Pod metadata包含以下几个部分:
* Pod的名字
* Pod的IP address
* Pod所属的namespace
* Pod所在的worker node名字
* Pod所属的service名字
* Container所需的CPU和memory
* Container的CPU和memory limit
* Pod的label
* Pod的annotation

其中, label和annotation只能通过downwardAPI volume获取, 其他metadata无论environment variable或downwardAPI volume都可以获取.

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
上述YAML文件中将Pod metadata全部放入environment variable. 其中, CPU和memory的request或limit可标注divisor, divisor表示资源单位, 默认为1(byte): 本例中CPU request的divisor为1m(metabyte), 因此CONTAINER_CPU_REQUEST_MILLICORES为15; memory limit的divisor为1Ki(kibibyte), 因此CONTAINER_MEMORY_LIMIT_KIBIBYTES为4096. 如下图:
![Pod metadata and attributes can be exposed to the pod through environment variables](/images/Kubernetes/metadata-2.png)

可进入Pod查看environment variables:
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
上述YAML文件将metadata挂靠在**/etc/downward**下. 如下图:
![Use a downwardAPI volume to pass metadata to the container](/images/Kubernetes/metadata-3.png)

需要注意的是, 当在volume中使用CPU和memory的limit或request时, 必须标注container名字, 每个container有不同的request和limit. 之所以label和annotation不能直接放入environment variables, 因为label和annotation会被Pod运行时更改, 因此需要放在volume中保持更新. 



## 2. Kubernetes API Server
Downward API虽然能为container提供Pod metadata, 但有时container需要除Pod之外的信息. Kubernetes为此提供了API Server.

### 2.1 Explore the Kubernetes REST API
在向kubernetes API发送请求前需要先了解这套API:
```sh
$ kubectl cluster-info
Kubernetes master is running at https://192.168.99.100:8443
```
由于API server使用HTTPS, 所以在访问该IP address前需要确定准备HTTPS认证; 或使用**kubectl proxy**启动一个proxy server与API server进行HTTPS连接:
```sh
$ kubectl proxy
Starting to serve on 127.0.0.1:8001
```
上述proxy会监听8001端口. Proxy不需要任何参数, 因为它会自动获取所需要的配置信息并自动连接到API Server.
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
Kubernetes将所有API分为好几个API group, group分为以下两种:
1. core group: REST路径为**/api/v1**或, **apiVersion: v1**
2. named groups: REST路径为**/apis/\<GROUP_NAME\>/\<VERSION\>**, 或**apiVersion:  \<GROUP_NAME\>/\<VERSION\>**, 例如: apiVersion: batch/v1

以Job为例, 其位于**/api/batch**的路径上:
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
上述为batch API group的描述, 包括version和其他信息. 以下是**/api/batch/v1**的路径访问结果:
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
其中**name**表示可访问的路径, **kind**表示所属的resource类型, namespaced表示是否属于某个namespace, verbs表示可进行的操作, 主要操作形式包括以下几种:
1. Create: 创建resource
2. Update: 有两种形式:
  1. Replace: 替代当前resource object中已存在的field
  2. Patch: 修改特定field
3. Read: 有三种形式:
  1. Get: 通过名字获得特定resource object
  2. List: 获得所有符合selector规则的resource object
  3. Watch: 获得resource object被更新后的结果
4. Delete: 删除一个resource object
5. 其他操作, 包含以下三种:
  1. Rollback: 回滚PodTemplate至上一个版本
  2. Read/Write Scale: 读取或更新replica数量
  3. Read/Write Status: 读取或更新resource object的状态

向**/apis/batch/v1/jobs**路径发送GET请求可获得cluster中的所有Job, 如下:
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
也可通过Job名字来访问该Job的配置细节:
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

### 2.2 Access the APi Server from within a Pod
上述所使用的方式仅限与local machine, 在container中则无法调用kubectl.  因此如果需要在Pod中与API server通讯, 则需要满足以下三个条件:
1. 找到API server的IP address
2. 保证对方是API server而不是其他人
3. 认证server

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
以上YAML文件创建了一个Pod, 其中container包含curl程序用于向API server发送请求. 然后需要获取Kubernetes API server的IP address和Port: Kubernetes提供了名为**kubernetes**的service作为API server的entry point, 可直接向**https://kubernetes**发送请求:
```sh
$ kubectl exec -it curl bash
root@curl:/# curl https://kubernetes
curl: (60) SSL certificate problem: unable to get local issuer certificate
...
```
由于还未配置HTTPS的certificates和private key, 所以暂时无法连接至API server. Kubernetes为Pod提供的默认Secret volume中含有HTTPS所需的certificate, 位置在**/var/run/secrets/kubernetes.io/serviceaccount/**:
```sh
root@curl:/# ls /var/run/secrets/kubernetes.io/serviceaccount/
ca.crt namespace token
```
其中, **ca.crt**为certificate. 使用certificate后尝试连接API server:
```sh
root@curl:/# curl --cacert /var/run/secrets/kubernetes.io/serviceaccount \
/ca.crt https://kubernetes
Unauthorized
```
虽然连接中使用了证书, 但API server需要认证连接的请求来自所管理的Pod, 而不是其他client, 因此需要在请求时加入token实现认证:
```sh
root@curl:/# TOKEN=$(cat /var/run/secrets/kubernetes.io/ serviceaccount/token)
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
自此Pod内container与API server的连接建立完毕, container可向API server发送请求来获取或修改cluster中的数据. Secret volume中还包含一个名为**namespace**的文件, 其中包含Pod所处的namespace名称, 可用于向API server发送请求:
```sh
root@curl:/# NS=$(cat /var/run/secrets/kubernetes.io/  serviceaccount/namespace)
root@curl:/# curl -H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/$NS/pods
{
  "kind": "PodList",
  "apiVersion": "v1",
  ...
```
整个流程如下图:
![Use the files from the default-token Secret to talk to the API server](/images/Kubernetes/metadata-4.png)

### 2.3 Simplify API Server Communication with Ambassador Container
上述步骤虽然可以实现Pod中的container与API server通信, 但操作过于复杂, 这时可使用Sidecar Pattern: 运行一个ambassador container作为代理, 帮助Pod中的其他container与API server建立连接.
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
上述YAML文件创建了一个Pod, 其中包含主程序main和代理程序ambassador. Ambassador会开放8001端口来接收请求并转发给API server, 这样main不需要配置任何certificate和token:
![Offload encryption, authentication, and server verification in an ambassador container](/images/Kubernetes/metadata-5.png)

### 2.4 Use Client Libraries to Talk to the API Server
除了ambassador, Kubernetes官方还为以下两个语言提供了API Client Libraries:
* Golang client—https://github.com/kubernetes/client-go
* Python—https://github.com/kubernetes-incubator/client-python

其他语言也可支持API Client Libraries:
* Java client by Fabric8—https://github.com/fabric8io/kubernetes-client
* Node.js client by tenxcloud—https://github.com/tenxcloud/node-kubernetes-client
* PHP—https://github.com/devstub/kubernetes-api-php-client
* Ruby—https://github.com/Ch00k/kubr
* Clojure—https://github.com/yanatan16/clj-kubernetes-api
* Scala—https://github.com/doriordan/skuber
* Perl—https://metacpan.org/pod/Net::Kubernetes

