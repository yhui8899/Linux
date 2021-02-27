

# 一、Pod资源限制

##### Pod和Container的资源请求和限制：

### 资源限制有两个：

##### 1、requests：创建pod时最低分配的资源，以requests值做资源调度分配的

##### 2、limits：对资源的总限制

```
•spec.containers[].resources.limits.cpu		
			#在spec下的containers下的resources下的limits下设置的，以层级关系来排列；
•spec.containers[].resources.limits.memory	
•spec.containers[].resources.requests.cpu	
•spec.containers[].resources.requests.memory	
```


**以mysql和wordpress为例**：

在一个Pod中创建db和wp两个容器

vim mysql_wordpress.yaml

```shell
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
spec:
  containers:
  - name: db
    image: mysql
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: "password"
    resources:                      #resources在containers的下一级
      requests:						#一般requests要比limits要小一些，主要做资源调度使用
        memory: "64Mi"				#最低分配64M内存
        cpu: "250m"					#1核CPU的25% 即0.25，
      limits:						#也可以设置为：1、1.5以此类推的数字，1是1核，1.5是1核半
        memory: "128Mi"			#限制最大可使用128M内存
        cpu: "500m"				#可使用0.5核CPU，这些设置与 docker的限制是一样的
  - name: wp
    image: wordpress
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"					#1核CPU的25% 即0.25
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**使用apply创建**：在一个配置文件中创建两个pod
```shell
kubectl apply -f mysql_wordpress.yaml			#创建和更新都可以用apply，
```
**查看pod分配到了那个node节点**
```shell
kubectl describe pod frontend			# frontend  是pod名称 （frontend 单词：前端的意思）
```
**查看143节点上跑pod的资源利用率**
```shell
 kubectl describe node 192.168.83.143     
```
**创建的pod如果没有指定命名空间，默认是在default下面**

**查看命名空间：**
```shell
kubectl   get  ns   				# ns  是namespace的缩写

[root@MASTER-2 ~]# kubectl get ns       #显示k8s中所有的命名空间
NAME          STATUS   AGE
default       Active   9d
kube-public   Active   9d
kube-system   Active   9d
```

## 二、重启策略（restartPolicy）

重启策略是决定了pod的故障之后所做的动作

```shell
主要有以下三重策略：

•Always：当容器终止退出后，总是重启容器，默认策略。

•OnFailure：当容器异常退出（退出状态码非0）时，才重启容器。

•Never:：当容器终止推出，从不重启容器。
```
可以通过kubectl edit来查看pod的配置和策略
```shell
kubectl edit pod nginx-dd6b5d745-xm9ps #查看nginx的配置信息和策略
或者：
kubectl edit deployment nginx-deployment    #查看或修改deployment资源对象中名为nginx-deployment的配置信息，也可以直接修改保存后生效！

```
**以nginx案例为例**

vim  pod3.yaml

```shell
---
apiVersion: v1
kind: Pod
metadata:
  name: foo
spec:
  containers:
    - name: nginx
      image: nginx
  restartPolicy: Always		# 这里设置的是always策略，当容器终止退出后，总是重启容器，默认策略。
```

**执行创建**：kubectl apply -f  pod3.yaml



## 三、健康检查（Probe）

#### Probe有以下两种类型：

**livenessProbe：**

如果检查失败，将杀死容器，根据Pod的restartPolicy来操作。

**readinessProbe：**	

如果检查失败，Kubernetes会把Pod从service endpoints中剔除。

#### Probe支持以下三种检查方法：

**httpGet**

发送HTTP请求，返回200-400范围状态码为成功。

**exec**

执行Shell命令返回状态码是0为成功。

**tcpSocket**

发起TCP Socket建立成功。

**查看endpoints**

```shell
kubectl get ep
```

### 健康检查示例如下：

**健康检查示例1：**

```
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec		#pod中显示的名称
spec:
  containers:
  - name: liveness
    image: busybox
    args:
    - /bin/sh
    - -c		#下面这行代码是先创建一个文件，30秒后删除healthy文件，在等600秒执行下面的健康检查
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600	
    livenessProbe:		#定义健康检查，如果检查失败，将杀死容器，根据Pod的restartPolicy来操作。
      exec:				# exec  执行的意思
        command:		# command  命令的意思	
        - cat
        - /tmp/healthy  #检测文件是否存在，如果返回值是非0则执行：restartPolicy: 中设置的规则；
      initialDelaySeconds: 5		#容器启动5秒后开始执行健康检查，可以自定义实践，秒为单位 
      periodSeconds: 5				#检查周期，每个5秒检查一次
```

**官网示例**：https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/

**健康检查示例2：**

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http			#pod中显示的名称
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/liveness		#镜像，这里是从k8s官方拉取镜像
    args:
    - /server
    livenessProbe:	#定义健康检查，如果检查失败，将杀死容器，根据Pod的restartPolicy来操作。
      httpGet:				#使用httpget的方式
        path: /healthz		#定义健康检查的URL
        port: 8080			#端口8080
        httpHeaders:			#定义http请求头信息
        - name: Custom-Header	#请求头信息
          value: Awesome
      initialDelaySeconds: 3	#容器启动5秒后开始执行健康检查，可以自定义实践，秒为单位 
      periodSeconds: 3			#检查周期，每个5秒检查一次
```



**健康检查示例3：**

```
apiVersion: v1
kind: Pod
metadata:
  name: goproxy		#pod中显示的名称
  labels:
    app: goproxy
spec:
  containers:
  - name: goproxy					
    image: k8s.gcr.io/goproxy:0.1		#镜像，这里是从k8s官方拉取镜像
    ports:
    - containerPort: 8080
    readinessProbe:	  #定义健康检查，如果检查失败，Kubernetes会把Pod从service endpoints中剔除。
      tcpSocket:			#使用socket来定义
        port: 8080			#端口8080
      initialDelaySeconds: 5	#容器启动5秒后开始执行健康检查，可以自定义实践，秒为单位 
      periodSeconds: 10			#检查周期，每个5秒检查一次
    livenessProbe:	#这里是以：livenessProbe:的方式来定义,上面是：readinessProbe类型，
      tcpSocket:		#使用socket来定义
        port: 8080		#端口8080
      initialDelaySeconds: 15		#容器启动15秒后开始执行健康检查，可以自定义实践，秒为单位 
      periodSeconds: 20				#检查周期，每个20秒检查一次
```

---------------------------------



## 四、调度约束

#### 1、nodeName用于将Pod调度到指定的Node名称上

**nodeName实例：**

使用nodeName调度到指定的NODE节点上：通过指定node的IP地址来调度，默认会绕过调度器直接分配到指定的NODE节点上；

```
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-example
  labels:
    app: nginx
spec:
  nodeName: 192.168.83.143			#指定pod分配到哪个NODE节点上
  containers:
  - name: nginx
    image: nginx:1.15
```


### 2、nodeSelector用于将Pod调度到匹配Label的Node上
nodeSelector用于将Pod调度到匹配Label的Node上，即会调度到指定的标签NODE节点上，会通过调度器调度

**给node配置标签**：	Label：标签的意思；

```shell
kubectl label nodes 192.168.83.142 test=A

kubectl label nodes 192.168.83.143 test=B
```
以上给两台NODE节点打的标签是：test=A,test=B

**查看刚刚给node节点配置的标签**：
```shell
kubectl get nodes --show-labels

[root@MASTER-1 demo]# kubectl get nodes --show-labels
NAME             STATUS   ROLES    AGE   VERSION   LABELS
192.168.83.142   Ready    <none>   14d   v1.12.2   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=192.168.83.142,test=A	#标签：test=A
192.168.83.143   Ready    <none>   14d   v1.12.2   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=192.168.83.143,test=B	#标签：test=B
```

**nodeSelector实例：**

将Pod调度到匹配的节点上

```shell
apiVersion: v1
kind: Pod
metadata:
  name: pod-label
  labels:
    app: nginx
spec:
  nodeSelector:		#nodeSelector用于将Pod调度到匹配Label的Node上，即会调度到指定的标签NODE节点上
    test: B			#这里是刚刚给NODE设置的标签以key，value（键值）的形式，刚刚的标签是：test=B
  containers:
  - name: nginx
    image: nginx:1.15
```


## 五、故障排查：

**Pod的几种状态：**
```shell
Pending   #Pod创建已经提交到Kubernetes。但是，因为某种原因而不能顺利创建。例如下载镜像慢，调度不成功。

Running  #Pod已经绑定到一个节点，并且已经创建了所有容器，至少有一个容器正在运行中，或正在启动或重新启动。

Succeeded	#Pod中的所有容器都已成功终止，不会重新启动。

Failed		#Pod的所有容器均已终止，且至少有一个容器已在故障中终止。也就是说，容器要么以非零状态退出，要么被系统终止。

Unknown	  #由于某种原因apiserver无法获得Pod的状态，通常是由于Master与Pod所在主机kubelet通信时出错。
```
**查看Pod状态**
```shell
kubectl describe TYPE/NAME          #查看pod的详细信息如：kubectl describe pod nginx-6gkfg

kubectl logs TYPE/NAME [-c CONTAINER]   #查看pod的日志如： kubectl logs tomcat-deployment-78d994bd79-nq6rk


kubectl exec POD [-c CONTAINER] --COMMAND [args...]  #进入pod容器中如：kubectl exec -it tomcat-deployment-78d994bd79-nq6rk /bin/bash 当一个pod有多个容器时可以只用-c 加容器名称来进入容器
```

**Pod故障分析**
```shell
Pending状态：pod启动不成功排查：

如：kubectl  describe  pod  xxxxxxpodname    ，查看报错提示；

Failed状态：如异常退出，容器在故障中终止：查看容器日志报错排查问题，

如：kubectl logs tomcat-749f7974b6-dw2cx	查看容器日志来排查

Unknown：apiserver无法获取pod当前的状态，pod状态是有kubelet上报的，

Running：pod在运行时出现问题，不能正常提供服务，可以进入容器中查看排查，如配置文件是否正确等等，

如：kubectl exec -it nginx-test /bin/bash

```

## 六、总结：

**Pod容器的三种分类：**

| Name                     | 中文描述   | 作用                  |
| :----------------------- | ---------- | --------------------- |
| Infrastructure Container | 基础容器   | 维护整个Pod的网络空间 |
| nitContainers            | 初始化容器 | 先于业务容器开始执行  |
| Containers               | 业务容器   | 并行启动              |



**yaml中kind的三种类型**

|             |                                                |      |
| ----------- | ---------------------------------------------- | ---- |
| Endpoints： | Endpoints可以把外部的链接到k8s系统中           |      |
| service     | 部署一个内部虚拟IP，其他deployment可以链接     |      |
| deployment  | 部署一个Pod，内部只能链接service，无法互相链接 |      |

**1、 Endpoints：案例：**

Endpoints可以把外部的链接到k8s系统中，如下将一个mysql连接到k8s中。

```shell
kind: Endpoints
apiVersion: v1
metadata:
  name: mysql-production
  namespace: test
subsets:
  - addresses:
      - ip: 10.0.0.82
    ports:
      - port: 3306

注解：
#10.0.0.xx：3306为外部mysql。
#namespace: test为命名空间
```

　**endpoint**是k8s集群中的一个资源对象，存储在etcd中，用来记录一个service对应的所有pod的访问地址。service配置selector，endpoint controller才会自动创建对应的endpoint对象；否则，不会生成endpoint对象.

**例如**：k8s集群中创建一个名为hello的service，就会生成一个同名的endpoint对象，ENDPOINTS就是service关联的pod的ip地址和端口。

**2、 service 案例:**

部署一个内部虚拟IP，其他deployment可以链接。

```shell
apiVersion: v1
    kind: Service
    metadata:
      name: mysql-production
      namespace: test
    spec:
      ports:
        - port: 3306
 #port: 3306为内部IP
 #name: mysql-production为service名称
 #此时mysql-production.test即为mysql的虚拟IP，其他可配置该字段连接到mysql，例如:

    "java","-Dspring.datasource.url=jdbc:mysql://mysql-production.test:3306/config", "-jar", "xxx.jar"
```

**3、deployment 案例：**

部署一个Pod，内部只能链接service，无法互相链接

```shell
apiVersion: apps/v1	  #指定deployment的资源版本，k8s中所有的资源对象都是通api进行分组实现的；
kind: Deployment		#指定资源名称；
metadata:				#资源的源数据
  name: nginx-deployment		#名称
  labels:
    app: nginx
spec:
  replicas: 3		 	#副本数，就是创建pod实例数量
  selector:				#标签选择器
    matchLabels:		
      app: nginx		#关联那一组pod
  template:					#控制对象		
    metadata:
      labels:
        app: nginx			#pod标签
    spec:
      containers:
      - name: nginx				#名称
        image: nginx:1.15.4			#容器的镜像及版本
        ports:
        - containerPort: 80			#容器端口
```



**镜像拉取策略：**

```shell
imagePullPolicy：IfNotPresent：Always：Never：  三种方式；

Always：每次都下载最新的镜像

Never：只使用本地镜像，从不下载

IfNotPresent：只有当本地没有的时候才下载镜像，默认使用该策略

使用方式在image字段下面添加此策略具体如下：

image: nginx:1.15
imagePullPolicy: IfNotPresent

```

**资源限制：**
```shell
    resources:                      #在contarner的下一级
      requests:						#一般requests要比limits要小一些，主要做资源调度使用
        memory: "64Mi"				#最低分配64M内存
        cpu: "250m"					#1核CPU的25% 即0.25，
      limits:						#也可以设置为：1、1.5以此类推的数字，1是1核，1.5是1核半
        memory: "128Mi"			    #限制最大可使用128M内存
        cpu: "500m"				    #可使用0.5核CPU，这些设置与 docker的限制是一样的
```
**重启策略：**
```shell
restartPolicy: Always、OnFailure、Never，	三种策略
```
**健康检查：**
```shell
livenessProbe、readinessProbe  两种类型；httpget 、exec、tcpSocket
```
**调度约束：**
```shell
nodeName、nodeSelector	两种类型；
```




