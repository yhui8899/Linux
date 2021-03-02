# 								Secret配置管理

**加密数据并存放Etcd中，让Pod的容器以挂载Volume方式访问**。

**应用场景**：token密码或凭据  ，一般情况下创建的secret是给Pod来调用的；

### 示例一：通过kubectl命令的方式来创建secret

```shell
echo -n 'admin' > ./username.txt				#创建用户名文件

echo -n '1f2d1e2e67df' > ./password.txt		#创建密码文件

kubectl create secret generic db-user-pass --from-file=./username.txt --from-file=./password.txt

#创建secret ：“generic”指定本地文件来创建， “db-user-pass”名称 ，”--from-file=./username.txt“指定用户名文件，“--from-file=./password.txt”指定密码文件
```

**查看刚刚创建的secret：**

kubectl get secret

```shell
[root@MASTER-1 secret]# kubectl get secret
NAME                  TYPE                                  DATA   AGE
db-user-pass          Opaque                                2      6m7s
default-token-hl7h6   kubernetes.io/service-account-token   3      20d
```

**查看secret详细信息：**

kubectl describe  secret  db-user-pass

```shell
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

### 示例二：

通过yaml格式来创建secret,首先要通过base64来编码

```shell
echo -n 'admin' | base64
YWRtaW4=
echo -n '1f2d1e2e67df' | base64
MWYyZDFlMmU2N2Rm
```

vim  mysecret.yaml

```shell
apiVersion: v1
kind: Secret					#资源对象是：Secret
metadata:                       #元数据信息
  name: mysecret                #secret的名称
type: Opaque                    #类型
data:                           #数据
  username: YWRtaW4=			#用户名为刚刚通过base64转换的编码
  password: MWYyZDFlMmU2N2Rm	#密码为刚刚通过base64转换的编码
```

 执行创建：kubectl create -f mysecret.yaml

以上两种方式都可以；

------

### 调用secret：

**创建个Pod来调用secret调用secret有两个方法：**

#### 方法一：

vim  secret-var.yaml

```shell
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: nginx
    image: nginx
    env:						#字段从这里开始，为key值设置一个环境变量
      - name: SECRET_USERNAME	#设置一个变量名，将下面的值赋值到这个变量名，变量名称可以随便定义；
        valueFrom:
          secretKeyRef:			#指定secret的key值，这里是secret类型；
            name: mysecret      #填写secret的名称		#来自于secret资源对象的名称，这是上面创建的secret的名称；
            key: username		# 将key值赋值给SECRET_USERNAME这个变量名
      - name: SECRET_PASSWORD	#设置一个变量名，将下面的值赋值到这个变量名，变量名称可以随便定义；
        valueFrom:
          secretKeyRef:			#指定secret的key值
            name: mysecret	    #填写secret的名称	#来自于secret资源对象的名称，这是上面创建的secret象的名称；
            key: password		# 将key值赋值给SECRET_PASSWORD这个变量名
```
**执行创建secret**
```shell
kubectl  create  -f   secret-var.yaml
```

**查看刚刚创建的pod**
```shell
kubectl get pod |grep mypod
```
**进入pod查看刚刚的变量**：
```shell
kubectl exec -it mypod /bin/bash

[root@MASTER-1 secret]# kubectl get pod |grep mypod
mypod                       1/1     Running     0          2m49s
[root@MASTER-1 secret]# kubectl exec -it mypod /bin/bash
root@mypod:/# echo $SECRET_USERNAME		#查看SECRET_USERNAME变量的值
admin
root@mypod:/# echo $SECRET_PASSWORD		#查看SECRET_PASSWORD变量的值
1f2d1e2e67df
root@mypod:/# 
```

#### 方法二：volume挂载的方式

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

**创建Pod**
```shell
kubectl create -f secret-vol.yaml 
```
**查看刚刚创建的pod**
```shell
kubectl get pod|grep mypod
```
**进入pod查看刚刚挂载的两个文件**
```shell
kubectl exec -it mypod /bin/bash

[root@MASTER-1 secret]# kubectl exec -it mypod /bin/bash
root@mypod:/# ls /etc/foo/
password  username				#挂载的两个文件
root@mypod:/# cat /etc/foo/username 		#查看username的文件内容是：admin
adminroot@mypod:/# cat /etc/foo/password 	#查看password的文件内容是：1f2d1e2e67df
1f2d1e2e67dfroot@mypod:/#   
```

**参考官方文档**：https://kubernetes.io/docs/concepts/configuration/secret/
