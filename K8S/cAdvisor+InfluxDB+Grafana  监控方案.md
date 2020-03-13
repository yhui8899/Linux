# cAdvisor+InfluxDB+Grafana  监控方案

Heapster+InfluxDB+Grafana

先创建一个monitor目录来存放yaml文件：

先部署Heapster:

vim  heapster.yaml

```
#创建一个ServiceAccount，因为它要获取API相关的资源，例如NODE，然后通过node来收集cAdvisor的数据；
apiVersion: v1
kind: ServiceAccount
metadata:
  name: heapster
  namespace: kube-system

---
#集群授权，角色绑定
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: heapster
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: ServiceAccount
    name: heapster
    namespace: kube-system

---
#部署heapster
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: heapster
  namespace: kube-system
spec:
  replicas: 1
  template:
    metadata:
      labels:
        task: monitoring
        k8s-app: heapster
    spec:
      serviceAccountName: heapster
      containers:
      - name: heapster
        image: registry.cn-hangzhou.aliyuncs.com/google-containers/heapster-amd64:v1.4.2
        imagePullPolicy: IfNotPresent
        command:
        - /heapster	
        - --source=kubernetes:https://kubernetes.default #指定连接K8S的APIserver的地址
        - --sink=influxdb:http://monitoring-influxdb:8086 #指定连接influxdb数据库的地址，通过DNS名称来连接的，所以必须要部署DNS服务器；

---
#部署service暴露出来
apiVersion: v1
kind: Service
metadata:
  labels:
    task: monitoring
    kubernetes.io/cluster-service: 'true'
    kubernetes.io/name: Heapster
  name: heapster
  namespace: kube-system
spec:
  ports:
  - port: 80
    targetPort: 8082
  selector:
    k8s-app: heapster

```

执行kubectl来部署：

kubectl apply -f heapster.yaml

查看刚刚部署的heapster:

kubectl get pods -n kube-system

```
[root@MASTER-1 monitor]# kubectl get pods -n kube-system
NAME                                    READY   STATUS    RESTARTS  AGE
coredns-56684f94d6-557xn                1/1     Running   12        13d
heapster-66687b8845-bzj85               1/1     Running   0         64s #刚刚部署的heapster
kubernetes-dashboard-7dffbccd68-swcjx   1/1     Running   32        30d
```

-------------------

部署InfluxDB数据库：

vim  influxdb.yaml

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: monitoring-influxdb
  namespace: kube-system
spec:
  replicas: 1
  template:
    metadata:
      labels:
        task: monitoring
        k8s-app: influxdb
    spec:
      containers:
      - name: influxdb
        image: registry.cn-hangzhou.aliyuncs.com/google-containers/heapster-influxdb-amd64:v1.1.1	#使用阿里云的镜像地址
        volumeMounts:		#定义volume存储
        - mountPath: /data		#挂载路径
          name: influxdb-storage		#存储名称
      volumes:		#volume存储
      - name: influxdb-storage		#存储名称和上面的一致即可
        emptyDir: {}		#空目录，临时存储，如果需要持久化存储的话需要修改；

---
#创建service暴露让grafana访问，默认使用了clusterIP；
apiVersion: v1
kind: Service
metadata:
  labels:
    task: monitoring
    kubernetes.io/cluster-service: 'true'
    kubernetes.io/name: monitoring-influxdb
  name: monitoring-influxdb
  namespace: kube-system
spec:
  ports:
  - port: 8086
    targetPort: 8086
  selector:
    k8s-app: influxdb
```

执行kubectl创建influxdb数据库：

kubectl apply -f influxdb.yaml 

查看刚刚创建爱的influxdb

kubectl get pod -n kube-system

```
[root@MASTER-1 monitor]# kubectl get pod -n kube-system
NAME                                    READY   STATUS    RESTARTS   AGE
coredns-56684f94d6-557xn                1/1     Running   12         13d
heapster-66687b8845-bzj85               1/1     Running   0          9m38s
kubernetes-dashboard-7dffbccd68-swcjx   1/1     Running   32         30d
monitoring-influxdb-864c767966-8c6xl    1/1     Running   0          62s
```

上面看到创建成功；

创建grafana将数据展示出来：

vim  grafana.yaml

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: monitoring-grafana
  namespace: kube-system
spec:
  replicas: 1
  template:
    metadata:
      labels:
        task: monitoring
        k8s-app: grafana
    spec:
      containers:
      - name: grafana
        image: registry.cn-hangzhou.aliyuncs.com/google-containers/heapster-grafana-amd64:v4.4.1
        ports:
          - containerPort: 3000
            protocol: TCP
        volumeMounts:
        - mountPath: /var
          name: grafana-storage
        env:			#定义相关需要处理的变量；
        - name: INFLUXDB_HOST
          value: monitoring-influxdb
        - name: GF_AUTH_BASIC_ENABLED
          value: "false"
        - name: GF_AUTH_ANONYMOUS_ENABLED
          value: "true"
        - name: GF_AUTH_ANONYMOUS_ORG_ROLE
          value: Admin
        - name: GF_SERVER_ROOT_URL
          value: /
      volumes:
      - name: grafana-storage
        emptyDir: {}

---
#部署service暴露出来
apiVersion: v1
kind: Service
metadata:
  labels:
    kubernetes.io/cluster-service: 'true'
    kubernetes.io/name: monitoring-grafana
  name: monitoring-grafana
  namespace: kube-system
spec:
  type: NodePort	#service以NodePort的类型来暴露；
  ports:
  - port : 80
    targetPort: 3000		#grafana的端口
  selector:
    k8s-app: grafana

```

执行kubectl创建grafana

kubectl apply -f grafana.yaml 

```
[root@MASTER-1 monitor]#  kubectl get pod -n kube-system
NAME                                    READY   STATUS    RESTARTS   AGE
coredns-56684f94d6-557xn                1/1     Running   12         13d
heapster-66687b8845-bzj85               1/1     Running   0          15m
kubernetes-dashboard-7dffbccd68-swcjx   1/1     Running   32         30d
monitoring-grafana-cd8b89587-2m54k      1/1     Running   0          59s
monitoring-influxdb-864c767966-8c6xl    1/1     Running   0          7m15s
```

查看grafana的service暴露的端口：

kubectl get svc -n kube-system 

```
[root@MASTER-1 monitor]#  kubectl get svc -n kube-system    
NAME                   TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)         AGE
heapster               ClusterIP   10.0.0.29    <none>        80/TCP          17m
kube-dns               ClusterIP   10.0.0.2     <none>        53/UDP,53/TCP   13d
kubernetes-dashboard   NodePort    10.0.0.50    <none>        443:30001/TCP   37d
monitoring-grafana     NodePort    10.0.0.55    <none>        80:33617/TCP    2m16s
monitoring-influxdb    ClusterIP   10.0.0.234   <none>        8086/TCP        8m32s
```

上面可以看到grafana的service暴露的端口是：33617，接下来可以用浏览器来访问，http://Node节点IP:33617

使用浏览器访问：http://192.168.83.142:33617  

![1576758988631](F:\文档笔记\Kubernetes\1576758988631.png)

