# ConfigMap配置管理

**与Secret类似，区别在于ConfigMap保存的是不需要加密配置信息**。

**应用场景**：应用程序配置

**使用redis简单的配置文件为例**：

创建一个redis.properties文件并写入内容：
### 实例1：
vim  redis.properties

```shell
redis.host=127.0.0.1
redis.port=6379
redis.password=123456
```

**通过kubectl 来创建一个configmap**
```shell
kubectl create configmap redis-config --from-file=./redis.properties
```
**查看刚刚创建的configmap:**
```shell
kubectl get configmap

[root@MASTER-1 configmap]# kubectl get configmap
NAME           DATA   AGE
redis-config   1      17s
```

**查看刚刚创建的configMap的数据**
```shell
kubectl describe cm redis-config

[root@MASTER-1 configmap]# kubectl describe cm redis-config
Name:         redis-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
redis.properties:		#列出redis.properties保存的数据，下面Pod引用这段配置时也会根据这个名称来生成一个配置文件，将如下配置写到配置文件中；
----
redis.host=127.0.0.1
redis.port=6379
redis.password=123456

Events:  <none>
```



**创建一个pod来调用configMap的数据：**

以volume的方式挂载进去：

vim  cm.yaml

```shell
apiVersion: v1
kind: Pod
metadata:
  name: mypod1	#pod名称
spec:
  containers:
    - name: busybox			
      image: busybox:1.28.4		#镜像名称
      command: [ "/bin/sh","-c","cat /etc/config/redis.properties" ]     #容器启动后执行的命令；
      volumeMounts:			    #定义一个volume，将下面的volumes挂载到容器中
      - name: config-volume		#引用下面volume定义的名称；
        mountPath: /etc/config	#挂载到容器的目录
  volumes:						    #定义需挂载的内容
    - name: config-volume		    #这个名称是给volume挂载时使用的
      configMap:				    #volume挂载的类型为：configMap
        name: redis-config	        #设置configmap的名称，将redis-config挂载到mypod容器中，会生成一个名为：redis.properties的文件，文件名根据kubectl describe cm redis-config查看到的名称来生成的；
  restartPolicy: Never		        #重启策略：Never,正常退出不重启；
```

**创建Pod命令如下：**
```shell
kubectl create -f cm.yaml
```
**查看刚刚创建的pod**
```shell
kubectl get pod|grep mypod

[root@MASTER-1 configmap]# kubectl get pod|grep mypod
mypod                       0/1     Completed   0          78s
```

mypod完成之后我们是无法进入到Pod里面的，因此我们文件中使用了cat命令，所以会将配置信息打印到控制台中，因此可以使用logs来查看；

```shell
kubectl logs mypod1

[root@MASTER-1 configmap]# kubectl logs mypod
redis.host=127.0.0.1
redis.port=6379
redis.password=123456
```
只要查看到如上信息来给程序读取就很容易了；

--------------------------------------------------------------------------------------

### 实例2：

以变量名的形式来保存，以key、value的形式

**创建一个configmap**

vim  myconfig.yaml

```shell
apiVersion: v1
kind: ConfigMap
metadata:
  name: myconfig
  namespace: default		#指定的命名空间
data:
  special.level: info	    #指定的一个level：为info，等下创建Pod的时候会调用special.level名称来取值；
  special.type: hello	    #指定的一个type：为hello，等下创建Pod的时候会调用special.type名称来取值；
```

**执行如下命令创建一个configmap：**
```shell
 kubectl apply -f myconfig.yaml 
```
**查看创建的cm**		#cm  是configumap的缩写；
```shell
kubectl get cm

[root@MASTER-1 configmap]# kubectl get cm
NAME           DATA   AGE
myconfig       2      25s		#看到有两个数据在里面了，证明是正常的；
redis-config   1      35m
```

**创建一个Pod来调用myconfig的数据：**

创建Pod的方式和secret是一样的；

vim  config-var.yaml

```shell
apiVersion: v1
kind: Pod
metadata:
  name: mypod2
spec:
  containers:
    - name: busybox		
      image: busybox
      command: [ "/bin/sh", "-c", "echo $(LEVEL) $(TYPE)" ]	    #容器启动后执行的命令，容器启动后打印变量；
      env:				            #为容器创建变量，定义变量；
        - name: LEVEL	            #定义变量名称，下面的key会赋值给这个变量
          valueFrom:
            configMapKeyRef:	    #指定configMap的key,这里是configmap类型的；
              name: myconfig		#指定configMap的名称为：myconfig，
              key: special.level	#这个key值是填写上面myconfig对应data下面的名称，将key赋值给上面的LEVEL变量
        - name: TYPE			    #定义变量名称，下面的key会赋值给这个变量
          valueFrom:
            configMapKeyRef:		#指定configMap的key,这里是configmap类型的；
              name: myconfig		#指定configMap的名称为：myconfig，
              key: special.type		#这个key值是填写上面myconfig对应data下面的名称，将key赋值给上面的TYPE变量
  restartPolicy: Never				#重启策略：Never，容器正常退出不重启；
```

**执行创建命令：**
```shell
kubectl  create -f  config-var.yaml
```
查看刚刚创建的pod名称为：mypod

```shell
kubectl get pod|grep mypod

[root@MASTER-1 configmap]# kubectl get pod|grep mypod
mypod                       0/1     Completed   0          2m26s
```

mypod完成之后我们是无法进入到Pod里面的，因此我们配置文件中使用了cat命令，所以会将配置信息打印到控制台中，因此可以使用logs来查看；

```shell
kubectl logs mypod

[root@MASTER-1 configmap]#  kubectl logs mypod       
info hello			#在控制台中已经打印输出刚刚创建的key_value的信息；
```

将如上信息提供给程序使用即可，configmap多用于管理应用程序的配置文件，如：nginx、java项目的配置文件、数据库的配置文件等；

**参考官方文档**：https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

### configmap 与 secret 区别

#### configmap：

`ConfigMap`是一种 API 对象，用来将非机密性的数据保存到健值对中。使用时可以用作环境变量、命令行参数或者存储卷中的配置文件。

`ConfigMap` 将您的环境配置信息和容器镜像解耦，便于应用配置的修改。当您需要储存机密信息时可以使用 Secret对象。

**注意：**

`ConfigMap` 并不提供保密或者加密功能。如果你想存储的数据是机密的，请使用 Secret，或者使用其他第三方工具来保证你的数据的私密性，而不是用 ConfigMap。

#### secret：

`Secret` 对象类型用来保存敏感信息，例如密码、OAuth 令牌和 SSH 密钥等，给Pod调用；