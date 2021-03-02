# StatefulSet 有状态应用
**有状态应用**：解决Pod独立生命周期，保持Pod启动顺序和唯一性，适用于数据库应用场景，特点如下：

1、稳定，唯一的网络标识符，持久化存储；

2、有序，优雅的部署和扩展、删除和终止；

3、有序，滚动更新；

### 实例1：
vim nginx-StatefulSet1.yaml
``` shell
apiVersion: apps/v1				#资源对象api版本
kind: StatefulSet				#资源对象：StatefulSet	
metadata:						#元数据信息
  name: web						#定义StatefulSet资源名称
spec:
  selector:						#标签选择器
    matchLabels:				#匹配标签， match：匹配的意思
      app: nginx				#匹配应用：nginx
  serviceName: "nginx"          #要对应service的名称一致
  replicas: 3					#副本数：3
  template:						#模板数据，被管理对象，也就是容器
    metadata:					#容器的元数据
      labels:					#容器的标签
        app: nginx		        #定义pod容器标签，一般和上面匹配的标签一致即可！
    spec:
      terminationGracePeriodSeconds: 10
      containers:				#容器
      - name: nginx				#容器名称
        image: nginx			#使用的镜像
        ports:
        - containerPort: 80		#容器端口
          name: web				#名称
        volumeMounts:			#定义挂载卷
        - name: www				#挂载名称
          mountPath: /usr/share/nginx/html	#定义挂载路径
  volumeClaimTemplates:			#使用卷的模板，也就是你请求什么样的资源
  - metadata:
      name: www									#这里与上面的挂载名称对应
    spec:
      accessModes: [ "ReadWriteOnce" ]			#可读写权限
      storageClassName: "managed-nfs-storage"  #指定上面创建的 storageClassName存储类名称
      resources:
        requests:
          storage: 1Gi			#指定资源大小：1G
```

#### 实例2：

**StatefulSet加handless service 无头服务**

vim nginx-StatefulSet2.yaml
```shell
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-statefulset
  namespace: default
spec:
  serviceName: nginx        #要对应service的名称一致
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

---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    targetPort: 80
  clusterIP: None       #None无头服务
  selector:
    app: nginx

```
**执行创建命令：**
```shell
kubectl apply -f nginx-StatefulSet.yaml
```
**查看创建的nginx-StatefulSet**

```shell
[root@k8s-master test]# kubectl get pods,svc
NAME                                          READY   STATUS    RESTARTS   AGE
pod/nginx-statefulset-0                       1/1     Running   0          14m
pod/nginx-statefulset-1                       1/1     Running   0          14m  #nginx-statefulset是唯一的网络标识，也是固定的dns名称，启动时会为每一个容器分配一个编号，删除的时候也是根据编号的顺序来删除的
pod/nginx-statefulset-2                       1/1     Running   0          14m

NAME                     TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
service/kubernetes       ClusterIP   10.0.0.1     <none>        443/TCP        33d
service/nginx            ClusterIP   None         <none>        80/TCP         13s
```
**解析测试**：
```shell
[root@k8s-master test]# kubectl exec -it busybox-8dbffc798-db294 sh
/ # nslookup nginx-statefulset-0.nginx      #nginx-statefulset-0 唯一标识符（也就是pod的名称）加上service的名称就能解析了
Server:    10.0.0.2
Address 1: 10.0.0.2 kube-dns.kube-system.svc.cluster.local

Name:      nginx-statefulset-0.nginx        
Address 1: 10.244.0.28 nginx-statefulset-0.nginx.default.svc.cluster.local  #唯一的域名，解析成功
```
statefulset和deployment的区别在于statefulset是有身份的，有如下三个身份要素：

**域名**： nginx-statefulset-0.nginx.default.svc.cluster.local （Pod名称+service名称+命名空间）

**主机名**：Pod的名称；

**存储（PVC）**：外部存储来保障数据的持久化；

如需访问不同命名空间下的资源需要在域名后面加上命名空间名称：
```shell
[root@k8s-master test]# kubectl exec -it busybox-8dbffc798-db294 sh
/ # nslookup metrics-server.kube-system         #解析如下
Server:    10.0.0.2
Address 1: 10.0.0.2 kube-dns.kube-system.svc.cluster.local

Name:      metrics-server.kube-system
Address 1: 10.0.0.141 metrics-server.kube-system.svc.cluster.local  #解析成功
/ #
```