# 								配置管理

## 一、Secret

##### 加密数据并存放Etcd中，让Pod的容器以挂载Volume方式访问。

##### 应用场景：token密码或凭据  ，一般情况下创建的secret是给Pod来调用的；

参考官方文档：https://kubernetes.io/docs/concepts/configuration/secret/

### 示例一：通过kubectl命令的方式来创建secret

```
echo -n 'admin' > ./username.txt				#创建用户名文件

echo -n '1f2d1e2e67df' > ./password.txt		#创建密码文件

kubectl create secret generic db-user-pass --from-file=./username.txt --from-file=./password.txt

#创建secret ：“generic”指定本地文件来创建， “db-user-pass”名称 ，”--from-file=./username.txt“指定用户名文件，“--from-file=./password.txt”指定密码文件
```

##### 查看刚刚创建的secret：

kubectl get secret

```
[root@MASTER-1 secret]# kubectl get secret
NAME                  TYPE                                  DATA   AGE
db-user-pass          Opaque                                2      6m7s
default-token-hl7h6   kubernetes.io/service-account-token   3      20d
```

##### 查看secret详细信息：

kubectl describe  secret  db-user-pass

```
[root@MASTER-1 secret]# kubectl describe secret db-user-pass
Name:         db-user-pass
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
password.txt:  12 bytes
username.txt:  5 bytes
```

### 示例二：通过yaml格式来创建secret

##### 首先要通过base64来编码

```shell
echo -n 'admin' | base64
YWRtaW4=
echo -n '1f2d1e2e67df' | base64
MWYyZDFlMmU2N2Rm
```

vim  mysecret.yaml

```
apiVersion: v1
kind: Secret					#资源对象是：Secret
metadata:
  name: mysecret
type: Opaque
data:
  username: YWRtaW4=			#用户名为刚刚通过base64转换的编码
  password: MWYyZDFlMmU2N2Rm	#密码为刚刚通过base64转换的编码
```

 执行创建：kubectl create -f mysecret.yaml

##### 以上两种方式都可以；

------

### 调用secret：

#### 		创建个Pod来调用secret

#### 		调用secret有两个方法：

### 方法一：

vim  secret-var.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: nginx
    image: nginx
    env:						#字段从这里开始，为key值设置一个环境变量
      - name: SECRET_USERNAME	#设置一个变量名，将下面的值赋值到这个变量名；
        valueFrom:
          secretKeyRef:			#指定secret的key值，这里是secret类型；
            name: mysecret		#来自于secret资源对象的名称，这是上面创建的secret资源对象的名称；
            key: username		# 将key值赋值给SECRET_USERNAME这个变量名
      - name: SECRET_PASSWORD	#设置一个变量名，将下面的值赋值到这个变量名；
        valueFrom:
          secretKeyRef:			#指定secret的key值
            name: mysecret		#来自于secret资源对象的名称，这是上面创建的secret资源对象的名称；
            key: password		# 将key值赋值给SECRET_PASSWORD这个变量名
```

kubectl  create  -f   secret-var.yaml

##### 查看刚刚创建的pod

kubectl get pod |grep mypod

##### 进入pod查看刚刚的变量：

kubectl exec -it mypod /bin/bash

```
[root@MASTER-1 secret]# kubectl get pod |grep mypod
mypod                       1/1     Running     0          2m49s
[root@MASTER-1 secret]# kubectl exec -it mypod /bin/bash
root@mypod:/# echo $SECRET_USERNAME		#查看SECRET_USERNAME变量的值
admin
root@mypod:/# echo $SECRET_PASSWORD		#查看SECRET_PASSWORD变量的值
1f2d1e2e67df
root@mypod:/# 
```

### 方法二：volume挂载的方式

vim  secret-vol.yaml 

```
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:	#定义一个volume，将下面的volumes挂载到这个volume中
    - name: foo					#定义一个volume挂载名称
      mountPath: "/etc/foo"		#volume挂载目录，将数据挂载到此目录中；
      readOnly: true			#开启只读；
  volumes:			#将这个volumes挂载到上面的volume指定的目录中
  - name: foo		#挂载的名称,这个名称要和上面的一致
    secret:			#表示要挂载的是secret类型；
      secretName: mysecret	#指定要挂载的secret资源名称，这里的资源名称是：mysecret,将mysecret挂载到mypod容器中的/etc/foo目录中，会以刚刚创建的username和password 作为文件名；

```

##### 创建Pod

kubectl create -f secret-vol.yaml 

##### 查看刚刚创建的pod

kubectl get pod|grep mypod

##### 进入pod查看刚刚挂载的两个文件

kubectl exec -it mypod /bin/bash

```
[root@MASTER-1 secret]# kubectl exec -it mypod /bin/bash
root@mypod:/# ls /etc/foo/
password  username				#挂载的两个文件
root@mypod:/# cat /etc/foo/username 		#查看username的文件内容是：admin
adminroot@mypod:/# cat /etc/foo/password 	#查看password的文件内容是：1f2d1e2e67df
1f2d1e2e67dfroot@mypod:/#   
```

------

## 二、ConfigMap

##### 与Secret类似，区别在于ConfigMap保存的是不需要加密配置信息。

##### 应用场景：应用配置

参考官方文档：https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

##### 使用redis简单的配置文件为例：

##### 创建一个redis.properties文件并写入内容：

vim  redis.properties

```
redis.host=127.0.0.1
redis.port=6379
redis.password=123456
```

##### 通过kubectl 来创建一个configmap

kubectl create configmap redis-config --from-file=./redis.properties

##### 查看刚刚创建的configmap:

kubectl get configmap

```
[root@MASTER-1 configmap]# kubectl get configmap
NAME           DATA   AGE
redis-config   1      17s
```

##### 查看刚刚创建的configMap的数据

kubectl describe cm redis-config

```
[root@MASTER-1 configmap]# kubectl describe cm redis-config
Name:         redis-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
redis.properties:		#列出redis.properties保存的数据，明文显示，因为configmap都是不加密的；
----
redis.host=127.0.0.1
redis.port=6379
redis.password=123456

Events:  <none>
```



##### 创建一个pod来调用configMap的数据：

以volume的方式挂载进去：

vim  cm.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: mypod	#pod名称
spec:
  containers:
    - name: busybox			
      image: busybox		#镜像名称
      command: [ "/bin/sh","-c","cat /etc/config/redis.properties" ] #执行的命令；
      volumeMounts:			#定义一个volume，将下面的volumes挂载到这个volume中
      - name: config-volume		#定义挂载的名称
        mountPath: /etc/config	#定义挂载路径
  volumes:						#定义需挂载的内容
    - name: config-volume		#挂载名称和上面的保持一致
      configMap:				#volume挂载的类型为：configMap
        name: redis-config	#指定要挂载的configmap名称，将redis-config挂载到mypod容器中，会生成一个名为：redis.properties的文件；
  restartPolicy: Never		#重启策略：Never,正常退出不重启；
```

#### 创建Pod命令如下：

kubectl create -f cm.yaml

##### 查看刚刚创建的pod

kubectl get pod|grep mypod

```
[root@MASTER-1 configmap]# kubectl get pod|grep mypod
mypod                       0/1     Completed   0          78s
```

mypod完成之后我们是无法进入到Pod里面的，因此我们文件中使用了cat命令，所以会将配置信息打印到控制台中，因此可以使用logs来查看；

kubectl logs mypod

```
[root@MASTER-1 configmap]# kubectl logs mypod
redis.host=127.0.0.1
redis.port=6379
redis.password=123456
```

##### 查看到如上信息来给程序读取就很容易了；



##### 也可以以变量名的形式来保存，以key、value的形式

##### 创建一个configmap

vim  myconfig.yaml

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: myconfig
  namespace: default		#指定的命名空间
data:
  special.level: info	#指定的一个level：为info
  special.type: hello	#指定的一个type：为hello
```

##### 执行如下命令创建一个configmap：

 kubectl apply -f myconfig.yaml 

##### 查看创建的cm		#cm  是configumap的缩写；

kubectl get cm

```
[root@MASTER-1 configmap]# kubectl get cm
NAME           DATA   AGE
myconfig       2      25s		#看到有两个数据在里面了，证明是正常的；
redis-config   1      35m
```

##### 在创建一个Pod来调用myconfig的数据：

##### 创建Pod的方式和secret是一样的；

vim  config-var.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: busybox		
      image: busybox
      command: [ "/bin/sh", "-c", "echo $(LEVEL) $(TYPE)" ]	#执行命令，容器启动后打印变量；
      env:				#为容器创建变量，定义变量；
        - name: LEVEL	#变量名称，下面的key会赋值给这个变量
          valueFrom:
            configMapKeyRef:	#指定configMap的key,这里是configmap类型的；
              name: myconfig		#指定configMap的名称为：myconfig，
              key: special.level	#将key赋值给上面的LEVEL变量
        - name: TYPE			#变量名称，下面的key会赋值给这个变量
          valueFrom:
            configMapKeyRef:		#指定configMap的key,这里是configmap类型的；
              name: myconfig		#指定configMap的名称为：myconfig，
              key: special.type		#将key赋值给上面的TYPE变量
  restartPolicy: Never				#重启策略：Never，容器正常退出不重启；
```

##### 执行创建命令：

kubectl  create -f  config-var.yaml

##### 查看刚刚创建的pod名称为：mypod

kubectl get pod|grep mypod

```
[root@MASTER-1 configmap]# kubectl get pod|grep mypod
mypod                       0/1     Completed   0          2m26s
```

mypod完成之后我们是无法进入到Pod里面的，因此我们配置文件中使用了cat命令，所以会将配置信息打印到控制台中，因此可以使用logs来查看；

kubectl logs mypod

```
[root@MASTER-1 configmap]#  kubectl logs mypod       
info hello			#在控制台中已经打印输出刚刚创建的key_value的信息；
```

##### 将如上信息提供给程序使用即可，configmap多用于管理应用程序的配置文件，如：nginx、java项目的配置文件、数据库的配置文件等；