---
title: ConfigMap and Secret
abbrlink: '95'
date: 2019-10-31 08:19:52
category:
  - K8s
tag:
  - K8s
keywords:
description:
---

## 1. Introduction
Container技术(例如Docker)提供了三种简易方式来为运行在container中的应用提供configuration:
1. 为container传递command-line arguments
2. 为container设置不同的environment variables
3. 将configuration file以Volume的形式挂在container上

Kubernetes也提供了两种Resources为container提供configuration:
1. ConfigMap: 用于存储配置信息
2. Secret: 用于存储敏感信息



## 2. Pass Command-line Arguments to Containers
Kubernetes允许传递给Pod中的container一些command-line arguments.

### 2.1 Define the Command and Arguments in Docker
Dockerfile提供了两个instructions:
1. ENTRYPOINT: 当container启动时运行的command
2. CMD: 主要为ENTRYPOINT提供参数, 也可执行command

当运行**docker run \<image\>**时会自动调用ENTRYPOINT和CMD, 也可以使用**docker run \<image\> \<arguments\>**来覆盖CMD中的参数.

* ENTRYPOINT存在两种形式: 
  1. exec: ["executable", "param1", "param2"]
  2. shell: command param1 param2
* CMD存在三种形式:
  1. exec: ["executable", "param1", "param2"]
  2. shell: command param1 param2
  3. parameters to ENTRYPOINT: ["param1", "param2"]

exec形式会直接开启一个进程来执行command, shell形式会先开启一个shell进程, 再在shell进程中执行command. 一般情况下使用exec形式即可.

### 2.2 Override the Command and Arguments in Kubernetes
Kubernetes提供了command和args来覆盖image中的ENTRYPOINT和CMD:
```yaml
...
kind: Pod
spec:
  containers:
  - image: some/image
    command: ["/bin/command"]
    args: ["arg1", "arg2", "arg3"]
...
```
所以一般不用定义ENTRYPOINT和CMD, 直接在Pod中定义即可. 注意: args中的数字必须用double quote(双引号)包裹, 字符串则不必.



## 3. Set Environment Variables for a Container
Kubernetes允许为Pod中的每个container定制不同的environment variables, 如下图:
![Environment variables can be set per container](/images/Kubernetes/config-1.png)

Environment variables之所以能作为配置参数, 因为所有脚本和语言都可以获取系统的environment variables; 但与command-line argument相同, 一旦container被启动, 则很难修改.
```yaml
...
kind: Pod
spec:
  containers:
  - image: luksa/fortune:env
    env:
    - name: INTERVAL
      value: "30"
    name: html-generator
...
```
Kubernetes还支持在YAML中使用之前设置的environment variables: 使用**$(VAR)**语法即可调用之前定义的environment variables:
```yaml
...
env:
  - name: FIRST_VAR
    value: "foo"
  - name: SECOND_VAR
    value: "$(FIRST_VAR)bar"
...
```
上述例子中, FIRST_VAR为foo, SECOND_VAR为foobar. 由于environment variable无法随时修改, 所以不同需求的Pod需要多个的YAML文件来标注不同的environment variables.



## 4. ConfigMap
ConfigMap作为Kubernetes的resource之一, 可将configuration中的内容与Pod定义分离, 以key/value的map形式作为configuration的格式. Container并不会直接读取ConfigMap中的配置信息, 而是通过environment variables或volume形式来读取配置信息, 如下图:
![Pods use ConfigMaps through environment variables and configMap volumes](/images/Kubernetes/config-2.png)

ConfigMap不与某个Pod绑定, 只与namespace绑定, 所以同一namespace下的Pod共享ConfigMap.

### 4.1 Create a ConfigMap
```sh
$ kubectl create configmap fortune-config --from-literal=sleep-interval=25
configmap "fortune-config" created
```
通过**kubectl create configmap** command可直接创建ConfigMap, 上述指令创造了一个名为fortune-config的ConfigMap, 包含一个entry, 其中key为sleep-interval, value为25. 也可在ConfigMap中创建多个entries:
```sh
$ kubectl create configmap myconfigmap --from-literal=foo=bar \
--from-literal=bar=baz --from-literal=one=two
```

调用**kubectl get configmap** command可查看当前ConfigMap
```sh
$ kubectl get configmap fortune-config -o yaml
apiVersion: v1
data:
  sleep-interval: "25"
kind: ConfigMap
metadata:
  creationTimestamp: 2016-08-11T20:31:08Z
  name: fortune-config
  namespace: default
  resourceVersion: "910025"
  selfLink: /api/v1/namespaces/default/configmaps/fortune-config
  uid: 88c4167e-6002-11e6-a50d-42010af00237
```

**--from-literal**表示直接写入Entry的key和value. 还可使用**--from-file**从文件中导入entry, 例如:
```sh
$ kubectl create configmap my-config --from-file=config-file.conf
```
上述新建的ConfigMap名为**my-config**, 包含一条entry, 其中key为**config-file.conf**(也就是文件名), value为config-file.conf文件里的内容. 还可从directory中将所有文件加入到ConfigMap中:
```sh
$ kubectl create configmap my-config --from-file=/path/to/dir
```
所有目录下的文件都会加入到ConfigMap中, 其中key为文件名, value为文件内容. ConfigMap也支持这几种方式的混合使用, 如下:
```sh
$ kubectl create configmap my-config \
--from-file=foo.json --from-file=bar=foobar.conf \
--from-file=config-opts/ --from-literal=some=thing
```
结果如下图:
![Create a ConfigMap from individual files, a directory, and a literal value](/images/Kubernetes/config-3.png)

### 4.2 Pass a ConfigMap Entry to a Container as an Environment Variable
在Pod中将ConfigMap中的entry传给container的environment variable是container读取ConfigMap的最简单方式:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-env-from-configmap
spec:
  containers:
  - image: luksa/fortune:env
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: fortune-config
          key: sleep-interval
...
```
上述例子中, container中设置environment variable的key为**INTERVAL**, value从名为**fortune-config**的ConfigMap中获取key为**sleep-interval**的value值. 若YAML文件中标注的ConfigMap不存在, 则该container不会被启动, 但Pod中的其他container照常运行; 当缺失的ConfigMap被创建后, container也会自动启动. 若在YAML中设置**configMapKeyRef.optional: true**, 即使ConfigMap不存在, container依然会启动.

### 4.3 Pass all Entries of a ConfigMap as Environment Variable
Kubernetes 1.6提供了一种可以将ConfigMap中所有entries导入到Container的environment variable的方法:
```yaml
spec:
  containers:
  - image: some-image
    envFrom:
    - prefix: CONFIG_
      configMapRef:
        name: my-config-map
...
```
注意, environment variable不支持一些特殊符号. 若ConfigMap中entry的key或value含有不合规的符号(例如: foo-bar), 则该entry不被导入environment variable.

### 4.4 Pass a ConfigMap Entry as a Command-line Argument
ConfigMap中的entry也可作为参数传入container:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-args-from-configmap
spec:
  containers:
  - image: luksa/fortune:args
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: fortune-config
          key: sleep-interval
    args: ["$(INTERVAL)"]
...
```
结果如下图:
![Pass a ConfigMap entry as a command-line argument](/images/Kubernetes/config-4.png)

### 4.5 Use a ConfigMap Volume to Expose ConfigMap Entries as Files
将ConfigMap挂载为volume只需要将volume的类型设置为configMap即可. 假设现在给Nginx添加配置文件**my-nginx-config.conf**, 文件内容如下:
```text
server {
  listen      80;
  server_name www.kubia-example.com;
  gzip        on;
  gzip_types text/plain application/xml;
  location {
    root  /usr/share/nginx/html;
    index index.html index.htm;
  }
}
```
将该文件和名为**sleep-interval**的文件放入同一文件夹中, 如下图:
![The contents of the configmap-files directory and its files](/images/Kubernetes/config-5.png)

调用**kubectl create configmmap**创建新的ConfigMap:
```sh
$ kubectl create configmap fortune-config --from-file=configmap-files
configmap "fortune-config" created
```

Nginx从**/etc/nginx/nginx.conf**路径中读取文件并添加到配置, 因此需要将ConfigMap挂在该路径上:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-configmap-volume
spec:
  containers:
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    ...
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
    ...
  volumes:
  ...
  - name: config
    configMap:
      name: fortune-config
 ...
```
结果如下:
![Pass ConfigMap entries to a pod as files in a volume](/images/Kubernetes/config-6.png)

也可以指定ConfigMap中的某一个或几个entry挂在volume上:
```yaml
volumes:
- name: config
  configMap:
    name: fortune-config
    items:
    - key: my-nginx-config.conf
      path: gzip.conf 
```
需要注意的是, 上述使用ConfigMap作为volume会覆盖挂载路径中的所有文件. 若**/etc/nginx/conf.d**中原本有其他文件, 则会因为fortune-config的挂载而消失. 为了保证不覆盖原本路径中的文件, 需在YAML中添加**subPath**属性:
```yaml
spec:
  containers:
  - image: some/image
    volumeMounts:
    - name: myvolume
      mountPath: /etc/someconfig.conf
      subPath: myconfig.conf 
```
这样就可以保证ConfigMap Volume只有myconfig.conf被挂载到container的/etc/someconfig.conf路径中, 如下图:
![Mount a single file from a volume](/images/Kubernetes/config-7.png)

也可以在YAML中设置ConfigMap Volume中文件的权限:
```yaml
volumes:
  - name: config
  configMap:
    name: fortune-config
    defaultMode: "6600" 
```

### 4.6 Update Config without Restarting the App
Environment variable和command-line argument的缺陷在于无法及时更新, 一旦Pod运行则无法修改. ConfigMap Volume则可无需container重启的同时更新配置信息. 调用**kubectl edit**可修改ConfigMap:
```sh
$ kubectl edit configmap fortune-config
```
由于Nginx不会主动查看配置文件是否更新, 所以需要向Nginx发送信号来重新加载:
```sh
$ kubectl exec fortune-configmap-volume -c web-server -- nginx -s reload
```
ConfigMap的修改和读取都是原子性的, 所以不必担心container会读取修改中的配置文件. Kubernetes会等待ConfigMap修改完毕后将新的文件写入新的文件夹中, 并relink到新的文件夹中. 注意: 如果在container中使用**subPath**而不是mount整个volume, 则文件无法随着ConfigMap的修改而刷新. 
若Pod中的container不支持自动检查ConfigMap是否被修改, 则不建议修改当前ConfigMap. 因为Pod随时可能被重新启动, 重启后的container会使用新的配置信息, 而旧的container还会使用旧的配置信息.



## 5. Screts
ConfigMap已经为container提供了完整的配置获取方案, 但有时需要存储一些敏感信息, 如: 秘钥, 证书. 为此Kubernetes提供Secrets, 可通过两种方式来获取信息:
1. 将Secret entry作为environment variables传入container
2. 将Secret entry作为volume挂在Pod上

### 5.1 default token Secret
为保证Secret的安全性, Secret永远不会写入物理存储设备, 只会保留在内存中. 每个Pod都会自带一些Secret, 可通过调用**kubectl describe pod** command来查看Pod绑定了哪些Secret:
```sh
$ kubectl describe pod <pod_name>
...
Volumes:
  default-token-t75t5:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-t75t5
...
```
也可通过**kubectl get secrets** command来查看当前namespace下的所有secrets:
```sh
$ kubectl get secrets
NAME                TYPE                                DATA AGE
default-token-t75t5 kubernetes.io/service-account-token 3    1d
```
若需要查看某个secret的具体信息, 可调用**kubectl describe secret**:
```sh
$ kubectl describe secret default-token-t75t5
Name:         default-token-t75t5
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: default
              kubernetes.io/service-account.uid: 0e856e7b-dfa3-11e9-8f93-4a00e35c70a2
Type:         kubernetes.io/service-account-token

Data
====
ca.crt:       1873 bytes
namespace:    7 bytes
token:        eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9...
```
其中**ca.crt**和**token**是为了让Pod与Kubernetes API server进行安全通信. 该Secret作为volume会被挂靠在Pod的**/var/run/secrets/kubernetes.io/serviceaccount**路径上.

### 5.2 Create a Secret
以之前的Nginx container为例, 可通过Secret在container中配置certificate和private key来让Nginx支持HTTPS. 首先需要生成certificate和private key并将其放置文件之中:
```sh
$ openssl genrsa -out https.key 2048
$ openssl req -new -x509 -key https.key -out https.cert -days 3650 \ 
-subj CN=www.kubia-example.com
```
为更好的表现Secret的性质, 再添加另外一个文件:
```sh
$ echo bar > foo
```
最后通过**kubectl create secret** command来创建一个Secret:
```sh
$ kubectl create secret generic fortune-https --from-file=https.key \
--from-file=https.cert --from-file=foo
secret "fortune-https" created
```

### 5.3 Compare ConfigMap and Secret
虽然ConfigMap和Secret都是ky-value的map格式, 但其实存在很大差异:
1. Secret entry中的key依然是明文形式, 但value使用Base43-encoded形式编码
2. Secret支持二进制数据, 因为Base64可对二进制数据进行编码
3. Secret支持stringData属性来放置该entry的value被Base64编码
4. 当Secret的entry被当做environment variable或volume时, entry会被自动解码, 因此container内的进程无需解码操作

### 5.4 Use the Secret in a Pod
为了让Nginx支持HTTPS, 需要将secret中的certificate和private key传给Nginx:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-https
spec:
  containers:
  - image: luksa/fortune:env
    name: html-generator
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: fortune-config
          key: sleep-interval
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
      readOnly: true
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
    - name: certs
      mountPath: /etc/nginx/certs/
      readOnly: true
    ports:
    - containerPort: 80
    - containerPort: 443
  volumes:
  - name: html
    emptyDir: {}
  - name: config
    configMap:
      name: fortune-config
      items:
      - key: my-nginx-config.conf
        path: https.conf
  - name: certs
    secret:
      secretName: fortune-https
```
结果如下:
![Combine a ConfigMap and a Secret to run your fortune-https pod](/images/Kubernetes/config-8.png)

也可以将Secret entry写入environment variable中:
```yaml
...
env:
  - name: FOO_SECRET
    valueFrom:
      secretKeyRef:
        name: fortune-https
        key: foo 
...
```