# 控制器

### 控制器也称为工作负载

#### 1.Deployment

Deployment适用于部署无状态应用，管理Pod和ReplicaSet，具有上线部署、副本设定、滚动升级、回滚等功能
提供声明式更新，例如只更新一个新的Image

ReplicaSet管理副本数和版本，如回滚就是通过ReplicaSet实现的；



#### 无状态：deployment

deployment认为所有的pod都是一样的，不用考虑顺序的要求，也不用考虑在哪个NODE上运行，随意扩容、缩容

使用deployment部署一个无状态pod

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment--test			#pod名称
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2			#创建的副本数
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.8
        ports:
        - containerPort: 80
~                           
```



#### 2、statuefuset

#### 有状态：statuefuset

例如：ETCD节点之间的关系，数据不完全一致，这种实例之间不对等的关系，以及依靠外包存储的应用，称为有状态；

解决Pod独立生命周期，保持Pod启动顺序和唯一性

1.稳定，唯一的网络标识符，持久存储
2.有序，优雅的部署和扩展、删除和终止
3.有序，滚动更新

statuefuset

#### 常规的service

headless service：无头服务，无集群ip和具体的IP，需要具体保证唯一的网络标识符所以需要利用DNS来保证网络唯一标识符，因此需要部署一个DNS来解析Pod的IP；



service：一组Pod访问策略，提供负载均衡和服务发现。

#####  创建一个statuefuset

vim sts.yaml

```
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: nginx-statefulset		#Pod名称，默认是：nginx-statefulset-0/1/2以此类推
  namespace: default
spec:
  serviceName: nginx
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

#### StatefulSet与Deployment区别：有身份的！

身份三要素：
域名
主机名
存储（PVC）

----------------------------------------------------------------

## 3、DaemonSet

在每一个Node上运行一个Pod
新加入的Node也同样会自动运行一个Pod
应用场景：Agent

创建一个daemonset资源

vim DaemonSet.yaml

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-elasticsearch
  labels:
    k8s-app: nginx-logging
spec:
  selector:
    matchLabels:
      name: nginx-elasticsearch
  template:
    metadata:
      labels:
        name: nginx-elasticsearch
    spec:
      containers:
      - name: fluentd-elasticsearch
        image: nginx
```

##### 查看一下刚刚创建的pod:

##### 		kubectl  get  pod  -o wide  

##### #查看创建的pod，会在两台NODE上各创建一个pod，如果指定了命名空间则需要-n 指定命名空间，如：kubectl  get  pod  -n kube-system

#### 示例：

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd-elasticsearch
        image: nginx
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:			#挂载卷
        - name: varlog				
          mountPath: /var/log		#挂载数据目录
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers	 #挂载数据目录
          readOnly: true					#开启只读
      terminationGracePeriodSeconds: 30	#优雅终止宽限期30秒，30秒后pod会自动关闭；
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

------------------------------------------------



## 4、Job

Job分为普通任务（Job）和定时任务（CronJob）
普通任务：一次性执行，比较适合临时跑一次任务

定时任务：有计划的执行

job非常适合离线数据处理，

#### 应用场景：离线数据处理，视频解码等业务

示例1：

vim  job.yaml

```
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never		# Never任务成功后不重启
  backoffLimit: 4				# 任务失败后重启4次就不在重启了
```

kubectl get job    # 查看资源对象

---------------------------------

## 5、CronJob

定时任务，像Linux的Crontab一样。
定时任务

#### 应用场景：通知，备份

vim  cronjob.yaml

```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *" #设定任务执行的时间每分钟执行1次，以：分、时、日、月、周的格式
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster	#echo 打印当前日期和hello；
          restartPolicy: OnFailure		# 异常退出会重启
```

###### 查看刚刚创建的cronjob  任务：

kubectl  get  cronjob

```
[root@MASTER-1 demo]# kubectl get cronjob
NAME    SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hello   */1 * * * *   False     0        <none>          8s
```

-------------------------------



##### 

