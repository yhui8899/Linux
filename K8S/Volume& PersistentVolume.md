# Volume& PersistentVolume

#### Volume	 本地数据卷，容器删除数据就丢失

Kubernetes中的Volume提供了在容器中挂载外部存储的能力

Pod需要设置卷来源（spec.volume）和挂载点（spec.containers.volumeMounts）两个信息后才可以使用相应的Volume

---------------

## Volume   			本地数据卷：

#### 一、emptyDir		（空目录）

创建一个空卷，挂载到Pod中的容器。Pod删除该卷也会被删除。
应用场景：Pod中容器之间数据共享

创建一个emptydir，创建两个centos容器来实验数据共享；

vim  emptydir.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:				
  containers:			#定义了两个容器，一个读一个写，实现资源共享；
  - name: write			#容器名称:write，代表这是个write写容器
    image: centos		#镜像busybox                  #下面是执行1到10的写命令
    command: ["bash","-c","for i in {1..10};do echo $i >> /data/hello;sleep 1;done"]
    volumeMounts:
    - name: data		#名称
      mountPath: /data		#挂载路径，容器路径
  
  - name: read			#容器名称:read，代表这是个read 读容器
    image: centos		#镜像centos
    command: ["bash","-c","tail -f /data/hello"]	#读取命令：	tail -f /data/hello
    volumeMounts:
      - name: data				#名称
        mountPath: /data		#挂载路径，容器路径
  volumes:			#定义数据卷来源
  - name: data		#名称	
    emptyDir: {}	#定义一个空目录
~                
```

##### 执行创建命令：

kubectl  apply  -f  emptydir.yaml

##### 查看刚创建的Pod

kubectl get pod my-pod

```
[root@MASTER-1 demo2]# kubectl get pod my-pod
NAME     READY   STATUS    RESTARTS   AGE
my-pod   2/2     Running   1          2m51s
```

##### 查看控制台输出： 刚刚创建了两个容器，一个write，一个read

kubectl logs my-pod -c read			#也可以加-f参数让控制台实时输出：kubectl logs my-pod -c read	-f

```
[root@MASTER-1 demo2]# kubectl logs my-pod -c read
1
2
3
4
5
6
7
8
9
10
```

##### 查看另外一个write容器

kubectl logs my-pod -c write				#如果一个Pod中有多个容器可以加 -c 容器名来查看容器

##### write容器没有输出信息，因为write只把内容写到hello文件中 ；

##### 可以进入Pod查看hello文件：

kubectl exec -it my-pod /bin/bash -c read		#进入read容器

```
[root@MASTER-1 demo2]# kubectl exec -it my-pod /bin/bash -c read
[root@my-pod /]# ls /data/hello 
/data/hello
```

kubectl exec -it my-pod /bin/bash -c write	   #进入write容器

------------

#### 二、hostPath:

挂载Node文件系统上文件或者目录到Pod中的容器。	#将宿主机的文件或目录挂载到Pod容器中
应用场景：Pod中容器需要访问宿主机文件

创建一个hostPath

vim  hostPath.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: my-pod			#Pod名称
spec:
  containers:
  - name: busybox		#容器名称
    image: busybox		#镜像：busybox
    args:
    - /bin/sh
    - -c
    - sleep 36000			#执行休眠命令，为了是容器不退出
    volumeMounts:
    - name: data
      mountPath: /data		#容器目录
  volumes:
  - name: data
    hostPath:		#指定的hostPath类型；
      path: /tmp	#路径，这个路径是指宿主机上的路径，将宿主机的tmp目录挂载到容器的/data目录
      type: Directory	#类型：directory（目录）
```

##### 执行创建命令：

kubectl  create  -f  hostPath.yaml

##### 查看刚刚创建的Pod

kubectl get pods my-pod -o wide	

```
[root@MASTER-1 demo2]# kubectl get pods my-pod -o wide
NAME     READY   STATUS    RESTARTS   AGE    IP            NODE             NOMINATED NODE
my-pod   1/1     Running   0          2m7s   172.17.70.6   192.168.83.142   <none>
```

如上看出Pod分配到了142节点上，因为挂载的是宿主机上的目录所以要验证测试；

##### 查看142节点上的/tmp目录：

```
[root@NODE-1 ~]# ll /tmp
总用量 0
drwxr-xr-x 2 root root 6 12月 12 21:49 test
drwx------ 2 root root 6 12月 12 20:14 vmware-root
```

```
进到busybox容器中查看挂载的目录：
```

kubectl exec -it my-pod sh

```
[root@MASTER-1 demo2]# kubectl exec -it my-pod sh
/ # ls /data/
test         vmware-root
/ # touch  abcd.txt			#创建一个abcd文件来测试
```

##### 查看142宿主机下的/tmp目录：

```
[root@NODE-1 ~]# ll /tmp
总用量 0
-rw-r--r-- 1 root root 0 12月 12 21:55 abcd.txt
drwxr-xr-x 2 root root 6 12月 12 21:49 test
drwx------ 2 root root 6 12月 12 20:14 vmware-root
```

如上信息可以看到/data/目录中的与142宿主机的/tmp目录中的文件目录一致；

---------------------

### PersistentVolume  持久化存储（简称PV）

PersistenVolume（PV）：对存储资源创建和使用的抽象，使得存储作为集群中的资源管理

### 网络数据卷

#### 以NFS存储为例：

##### 在两台Node节点上安装NFS  （143节点做NFS的服务器）

yum  install nfs-utils -y			#这个软件包含服务端和客户端，所以客户端也需要安装该软件包；

##### 修改配置文件添加如下内容：

vim  /etc/exports

```
/data/nfs  *(rw,no_root_squash)
注释：
*：所有的来源IP都可以访问
rw: 给目录分配读写的权限
```

##### 启动NFS服务：

systemctl  start nfs

ps -ef|grep nfs

```
[root@NODE-2 ~]# ps -ef|grep nfs
root      46207      2  0 22:06 ?        00:00:00 [nfsd4_callbacks]
root      46213      2  0 22:06 ?        00:00:00 [nfsd]
root      46214      2  0 22:06 ?        00:00:00 [nfsd]
root      46215      2  0 22:06 ?        00:00:00 [nfsd]
root      46216      2  0 22:06 ?        00:00:00 [nfsd]
root      46217      2  0 22:06 ?        00:00:00 [nfsd]
root      46218      2  0 22:06 ?        00:00:00 [nfsd]
root      46219      2  0 22:06 ?        00:00:00 [nfsd]
root      46220      2  0 22:06 ?        00:00:00 [nfsd]
root      46277   1390  0 22:06 pts/0    00:00:00 grep --color=auto nfs
```

##### NFS挂载测试，使用142节点来做客户端挂载命令如下：

```
mount -t nfs 192.168.83.143:/data/nfs /data/
```

##### 查看挂载情况：

```
[root@NODE-1 ~]# df -h|grep nfs   
192.168.83.143:/data/nfs   36G  7.4G   29G   21% /data
```

##### 如上信息显示142节点已成功挂载143节点的NFS

示例如下：创建一个nginx的Pod来演示

vim  nfs.yaml

```
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
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
        image: nginx
        volumeMounts:
        - name: wwwroot
          mountPath: /usr/share/nginx/html
        ports:
        - containerPort: 80
      volumes:
      - name: wwwroot
        nfs:
          server: 192.168.83.143
          path: /data/nfs
```

注解如下：

```
apiVersion: apps/v1beta1
kind: Deployment		#定义资源对象类型
metadata:
  name: nginx-deployment		#Pod名称
spec:
  replicas: 3					#Pod副本数
  selector:						#标签选择器相关，如果没有这块是无法匹配到是哪组Pod的
    matchLabels:				#匹配标签
      app: nginx				#名称：nginx
  template:
    metadata:					#元数据
      labels:					#labels标签匹配
        app: nginx				#labels标签名称：nginx
    spec:
      containers:				#容器相关
      - name: nginx				#Pod容器名称：nginx
        image: nginx			#使用的镜像：nginx
        volumeMounts:			#定义挂载卷相关
        - name: wwwroot			#挂载名称
          mountPath: /usr/share/nginx/html			#挂载到指定的路径
        ports:			#ports 端口相关
        - containerPort: 80			#容器端口：80
      volumes:				#volumes卷相关，即数据卷来源；
      - name: wwwroot		#名称：wwwroot
        nfs:				#volume类型类型是：nfs
          server: 192.168.83.143	#NFS服务器：192.168.83.143
          path: /data/nfs			#挂载的源路径，即NFS服务器的路径
          
 #NFS网络数据卷使用方式和本地数据卷一样的，需要先设置数据源然后挂载到哪个位置；
```

##### 执行创建命令：

kubectl  apply  -f  nfs.yaml

##### 查看创建的Pod

kubectl  get  pods

```
[root@MASTER-1 demo2]# kubectl get pod 
NAME                               READY   STATUS    RESTARTS   AGE
frontend                           2/2     Running   56         26d
my-pod                             1/1     Running   3          2d23h
nginx-cdb6b5b95-k7khh              1/1     Running   27         26d
nginx-cdb6b5b95-lc5fm              1/1     Running   27         26d
nginx-cdb6b5b95-rd99m              1/1     Running   27         26d
nginx-deployment-77d885978-6w8r8   1/1     Running   0          4m1s
nginx-deployment-77d885978-78bpv   1/1     Running   0          4m1s
nginx-deployment-77d885978-lhc7f   1/1     Running   0          4m1s
nginx-test                         1/1     Running   25         23d
#上面RESTARTS状态为0的三个nginx就是刚刚创建的
```

##### 进入nginx容器查看nfs是否挂载成功：

kubectl exec -it nginx-deployment-77d885978-6w8r8 /bin/bash

##### 执行查看挂载状态：

cat /proc/mounts |grep nfs

```
root@nginx-deployment-77d885978-6w8r8:/# cat /proc/mounts |grep nfs        
192.168.83.143:/data/nfs /usr/share/nginx/html nfs4 rw,relatime,vers=4.1,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,port=0,timeo=600,retrans=2,sec=sys,clientaddr=192.168.83.143,local_lock=none,addr=192.168.83.143 0 0
#查看挂载目录：
root@nginx-deployment-77d885978-6w8r8:/# ls /usr/share/nginx/html/
xiaofeige				#这个目录是安装宿主机上安装NFS的时候测试时创建的；
#接下来在143NFS服务器上创建一个index.html页面测试：
root@nginx-deployment-77d885978-6w8r8:/# ls /usr/share/nginx/html/
index.html  xiaofeige
#上面看到又刚在143宿主机上创建的index文件了
index.html文件内容如下：
<h1>hello world </h1>
```

由于刚刚创建的这组Pod原来已经创建过service了所以可以直接通过宿主机IP加端口访问刚刚创建的index页面

http://192.168.83.142:30008

访问页面出现：hello world  表示正常;

这就是让Pod如何去使用远程存储数据，这样每个Pod的数据就是持久化了，即使Pod宕机数据也保留在远程存储中，数据不会丢失或删除；

------------------------------------

## PersistentVolumeClaim   简称：PVC

PersistentVolumeClaim（PVC）：让用户不需要关心具体的Volume实现细节（即无需关心使用什么类型存储，只关心使用多大的容量空间）

创建实例如下：这里存储以NFS为例；

##### 首先创建一个PV：定义数据卷

vim pv.yaml

```
apiVersion: v1
kind: PersistentVolume			#定义资源对象类型（PersistentVolume简称：PV）
metadata:
  name: my-pv			#创建资源名称（即PV名称）
spec:
  capacity:			#定义容量
    storage: 5Gi	#定义PV存储大小：5G		
  accessModes:		#访问模式；
    - ReadWriteMany		#读写
  nfs:					#存储类型是：NFS
    path: /data/nfs/wwwroot		#存储路径，该目录必须要存在，否则Pod无法挂载并且容器也无法启动；
    server: 192.168.83.143		#NFS服务器地址
```

##### 执行创建PV命令：

kubectl  apply  -f  pv.yaml

##### 查看创建的pv:

kubectl get pv

```
[root@MASTER-1 demo2]# kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM            STORAGECLASS   REASON   AGE
my-pv   5Gi        RWX            Retain           Available    default/my-pvc                           27m

#STATUS状态为：Available表示可用；
```

如上信息所示PV已创建完成；

##### 创建一个Pod：

vim  pod-pvc.yaml

```
#容器应用
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
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
        image: nginx
        volumeMounts:
        - name: wwwroot
          mountPath: /usr/share/nginx/html
        ports:
        - containerPort: 80		#以上配置与上面静态PV配置一样，只需修改下面的挂载卷即可；
      volumes:				#定义数据卷来源，
      - name: wwwroot		#定义挂载名称；
        persistentVolumeClaim:		#类型：persistentVolumeClaim（动态供给）
          claimName: my-pvc			#指定上面pv.yaml文件中定义的PV名称：my-pvc
---
#卷需求示例 （PVC与PV进行绑定）
apiVersion: v1
kind: PersistentVolumeClaim			#定义资源类型：（绑定的对象：PersistentVolumeClaim）
metadata:
  name: my-pvc				#PVC名称
spec:
  accessModes:			#访问模式
    - ReadWriteMany		#可读写：ReadWriteMany	
  resources:			#请求的资源
    requests:
      storage: 5Gi     #设置定义的存储大小：5G
      
 #Pod需要时很强PVC存储，通常容器应用与挂载卷需求都是在一个yaml文件中，PVC与PV绑定最主要的关系就是存储容量，PV会根据容量来匹配PVC，然后就是访问模式，容量和访问模式都能匹配到才能绑定成功
```

执行kubectl创建Pod：

kubectl  apply  -f  pod-pvc.yaml

查看刚创建的Pod：

kubectl  get pod

```
[root@MASTER-1 demo2]# kubectl get pod
NAME                                READY   STATUS    RESTARTS   AGE
frontend                            2/2     Running   56         27d
my-pod                              1/1     Running   3          3d1h
nginx-cdb6b5b95-k7khh               1/1     Running   27         26d
nginx-cdb6b5b95-lc5fm               1/1     Running   27         26d
nginx-cdb6b5b95-rd99m               1/1     Running   27         26d
nginx-deployment-8497f6db64-675xs   1/1     Running   0          29m
nginx-deployment-8497f6db64-gww9d   1/1     Running   0          29m
nginx-deployment-8497f6db64-lsqhl   1/1     Running   0          29m
nginx-test                          1/1     Running   25         23d
#RESTART状态为0的是刚刚创建的pod
```

##### 查看PV和PVC绑定：

kubectl  get  pv,pvc

```
[root@MASTER-1 demo2]# kubectl get pv,pvc
NAME                     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM            STORAGECLASS   REASON   AGE
persistentvolume/my-pv   5Gi        RWX            Retain           Bound    default/my-pvc                           30m

NAME                           STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/my-pvc   Bound    my-pv    5Gi        RWX                           30m
```

##### 上面看到PV与PVC进行了绑定，状态是Bound，表示完成可以正常使用；

在NFS服务器中创建index.html页面内容如下：

```
<h1>hello world!123-test </h1>
```

##### 进入Pod查看文件内容：

kubectl exec -it nginx-deployment-8497f6db64-675xs /bin/bash

```
[root@MASTER-1 demo2]# kubectl exec -it nginx-deployment-8497f6db64-675xs /bin/bash
root@nginx-deployment-8497f6db64-675xs:/# cat /usr/share/nginx/html/index.html 
<h1>hello world!123-test </h1>
root@nginx-deployment-8497f6db64-675xs:/# 
```

由于刚刚创建的这组Pod原来已经创建过service了所以可以直接通过宿主机IP加端口访问刚刚创建的index页面

http://192.168.83.142:30008

访问页面出现：hello world!123-test   表示成功！

注意：默认情况下Pod删除后PV还保留并且无法在使用了需要手工删除，默认只删除Pod和PVC；

-------------------------

### PersistentVolume 动态供给

Dynamic Provisioning机制工作的核心在于StorageClass的API对象。
StorageClass声明存储插件，用于自动创建PV。

以NFS作为后端存储

vim  storageclass-nfs.yaml

```
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass				#使用资源对象：StorageClass	
metadata:
  name: managed-nfs-storage		#源数据名称：managed-nfs-storage 应用人员根据此名称来申请资源的
provisioner: fuseim.pri/ifs		#标识，取决于存储插件里面的，由于NFS不支持动态供给所以需要安装插件来完成动态创建PV的工作
```

创建NFS插件，主要用于NFS完成动态供给，动态创建PV工作的

部署动态创建PV的插件

vim  deployment-nfs.yaml

```
apiVersion: apps/v1beta1
kind: Deployment			#资源对象：Deployment
metadata:
  name: nfs-client-provisioner		#名称：提供者，即服务器名称；
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      imagePullSecrets:		#用不到，如果是镜像在自己的私有仓库的话拉取认证需要配置的
        - name: registry-pull-secret
      serviceAccount: nfs-client-provisioner  #这里引用的是下面创建的：serviceAccount
      containers:
        - name: nfs-client-provisioner   #容器名称
          image: lizhenliang/nfs-client-provisioner:v2.0.0	#拉取镜像地址
          volumeMounts:		#定义挂载点
            - name: nfs-client-root		#挂载名称	
              mountPath: /persistentvolumes		#挂载路径
          env:		#变量
            - name: PROVISIONER_NAME		#变量名称	
              value: fuseim.pri/ifs			#变量值，赋值给：PROVISIONER_NAME
            - name: NFS_SERVER				#变量名称
              value: 192.168.83.143			#变量值，赋值给：NFS_SERVER
            - name: NFS_PATH				#变量名称
              value: /data/nfs				#变量值，赋值给：NFS_PATH
      volumes:		#定义数据卷
        - name: nfs-client-root		#数据卷名称
          nfs:						#存储类型是：nfs
            server: 192.168.83.143	#存储服务器地址：192.168.83.143	
            path: /data/nfs			#服务器存储路径，即数据目录
```

这配置与GitHub上面的一样：

GitHub地址：https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client

由于部署动态创建PV的插件需要访问Apiserver所以要进行授权

vim rbac.yaml 

```
#创建一个ServerAccount
apiVersion: v1
kind: ServiceAccount		#资源对象：ServiceAccount
metadata:
  name: nfs-client-provisioner	#定义ServiceAccount名称在上面的deployment-nfs.yaml文件中被调用，以及下面的角色绑定也要调用；

---

kind: ClusterRole	#角色：ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: nfs-client-provisioner-runner	#定义名称
rules:			#以下是资源访问权限
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["list", "watch", "create", "update", "patch"]

---
kind: ClusterRoleBinding	#角色绑定：ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: run-nfs-client-provisioner		#定义名称
subjects:	
  - kind: ServiceAccount		#绑定到：ServiceAccount
    name: nfs-client-provisioner	#名称需要和上面ServiceAccount的名称一致
    namespace: default			#命名空间：default 默认
roleRef:			#绑定角色
  kind: ClusterRole		角色是：ClusterRole
  name: nfs-client-provisioner-runner	#角色名称，和上面ClusterRole的名称一致即可
  apiGroup: rbac.authorization.k8s.io
```

执行创建命令顺序如下：

```
storageclass-nfs.yaml

kubectl apply -f rbac.yaml 

kubectl apply -f deployment-nfs.yaml 
```

查看刚刚创建的 storageclass

kubectl get storageclass

```
[root@MASTER-1 storage-class]# kubectl get storageclass
NAME                  PROVISIONER      AGE
managed-nfs-storage   fuseim.pri/ifs   2m53s 
```

查看刚创建的Pod，即自动创建PV的容器

```
[root@MASTER-1 storage-class]# kubectl get pod
NAME                                      READY   STATUS    RESTARTS   AGE
frontend                                  2/2     Running   58         27d
my-pod                                    1/1     Running   4          3d23h
nfs-client-provisioner-84867cff56-667c5   1/1     Running   0          2m25s  #这个就是已经启动成功了，作为一个Pod在集群中运行，当你去申请这个资源的时候这个Pod会自动帮你去创建

nginx-cdb6b5b95-k7khh                     1/1     Running   28         27d
nginx-cdb6b5b95-lc5fm                     1/1     Running   28         27d
nginx-cdb6b5b95-rd99m                     1/1     Running   28         27d
nginx-deployment-8497f6db64-675xs         1/1     Running   1          22h
nginx-deployment-8497f6db64-gww9d         1/1     Running   1          22h
nginx-deployment-8497f6db64-lsqhl         1/1     Running   1          22h
nginx-test                                1/1     Running   26         24d
```

动态供给流程：

kubectl ——>StatefulSet（有状态资源对象）——>managed-nfs-storage(StorageClass) ——>nfs-client-provisioner(Pod) ——>NFS-192.168.83.143

下面来做实验：

vim  nginx-demo.yaml

```
#创建一个无头服务
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
#创建一个StatefulSet有状态应用
apiVersion: apps/v1
kind: StatefulSet		#资源对象：StatefulSet	
metadata:		#元数据
  name: web		#元数据名称
spec:
  selector:			#标签选择器
    matchLabels:	#匹配标签， match：匹配的意思
      app: nginx	#匹配应用：nginx
  serviceName: "nginx"
  replicas: 3			#副本数：3
  template:				#模板
    metadata:		#元数据
      labels:		#标签
        app: nginx	#标签名称
    spec:
      terminationGracePeriodSeconds: 10
      containers:	#容器
      - name: nginx		#容器名称
        image: nginx	#使用的镜像
        ports:
        - containerPort: 80		#容器端口
          name: web				#名称
        volumeMounts:	#定义挂载卷
        - name: www		#挂载名称
          mountPath: /usr/share/nginx/html	#定义挂载路径
  volumeClaimTemplates:		#使用卷的模板，也就是你请求什么样的资源
  - metadata:
      name: www		#这里与上面的挂载名称对应
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "managed-nfs-storage"  #指定上面创建的 storageClassName存储类名称
      resources:
        requests:
          storage: 1Gi		#指定资源大小：1G
```

官方案例：https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/

执行创建命令：

 kubectl apply -f nginx-demo.yaml

查看刚刚创建的Pod

kubectl get pods

```
[root@MASTER-1 storage-class]# kubectl get pods
NAME                                      READY   STATUS    RESTARTS   AGE
frontend                                  2/2     Running   58         28d
my-pod                                    1/1     Running   4          4d
nfs-client-provisioner-84867cff56-667c5   1/1     Running   0          32m
nginx-cdb6b5b95-k7khh                     1/1     Running   28         27d
nginx-cdb6b5b95-lc5fm                     1/1     Running   28         27d
nginx-cdb6b5b95-rd99m                     1/1     Running   28         27d
nginx-deployment-8497f6db64-675xs         1/1     Running   1          23h
nginx-deployment-8497f6db64-gww9d         1/1     Running   1          23h
nginx-deployment-8497f6db64-lsqhl         1/1     Running   1          23h
nginx-test                                1/1     Running   26         24d
web-0                                     1/1     Running   0          43s
web-1                                     1/1     Running   0          39s
web-2                                     1/1     Running   0          36s
#上面三个web就是刚刚创建的并且启动成功，有状态部署，状态表示为0-1-2
```

下面我们来看下有状态应用存储

我们来看下PV和PVC

 kubectl get pv,pvc

```
[root@MASTER-1 storage-class]#  kubectl get pv,pvc
NAME                                                                          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM               STORAGECLASS          REASON   AGE
persistentvolume/default-www-web-0-pvc-9c9a6b8c-200d-11ea-a147-000c29100356   1Gi        RWO            Delete           Bound    default/www-web-0   managed-nfs-storage            3m20s
persistentvolume/default-www-web-1-pvc-9f071a7b-200d-11ea-a147-000c29100356   1Gi        RWO            Delete           Bound    default/www-web-1   managed-nfs-storage            3m16s
persistentvolume/default-www-web-2-pvc-a12d0e60-200d-11ea-a147-000c29100356   1Gi        RWO            Delete           Bound    default/www-web-2   managed-nfs-storage            3m12s
persistentvolume/my-pv                                                        5Gi        RWX            Retain           Bound    default/my-pvc                                     23h

NAME                              STATUS   VOLUME                                                       CAPACITY   ACCESS MODES   STORAGECLASS          AGE
persistentvolumeclaim/my-pvc      Bound    my-pv                                                        5Gi        RWX                                  23h
persistentvolumeclaim/www-web-0   Bound    default-www-web-0-pvc-9c9a6b8c-200d-11ea-a147-000c29100356   1Gi        RWO            managed-nfs-storage   3m20s
persistentvolumeclaim/www-web-1   Bound    default-www-web-1-pvc-9f071a7b-200d-11ea-a147-000c29100356   1Gi        RWO            managed-nfs-storage   3m16s
persistentvolumeclaim/www-web-2   Bound    default-www-web-2-pvc-a12d0e60-200d-11ea-a147-000c29100356   1Gi        RWO            managed-nfs-storage   3m13s
```

如上信息可以看到我们刚刚没有创建PV和PVC，而是自动帮我们创建了PV和PVC并且进行了绑定，也会在NFS服务器上面自动创建目录：

查看自动创建的目录如下：

```
[root@NODE-2 ~]# cd /data/nfs/
[root@NODE-2 nfs]# ll
总用量 4
drwxrwxrwx 2 root root  6 12月 16 22:09 default-www-web-0-pvc-9c9a6b8c-200d-11ea-a147-000c29100356
drwxrwxrwx 2 root root  6 12月 16 22:09 default-www-web-1-pvc-9f071a7b-200d-11ea-a147-000c29100356
drwxrwxrwx 2 root root  6 12月 16 22:09 default-www-web-2-pvc-a12d0e60-200d-11ea-a147-000c29100356
```

到此基本体现出自动创建PV和有状态存储方面应用；

