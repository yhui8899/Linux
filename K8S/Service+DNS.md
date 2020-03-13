# 							Service+DNS

### 四个知识点：

1.Pod与Service的关系
2.Service类型
3.Service代理模式
4.DNS

----------------------------

•防止Pod失联
•定义一组Pod的访问策略
•支持ClusterIP，NodePort以及LoadBalancer三种类型
•Service的底层实现主要有iptables和ipvs二种网络模式

-----------------------

## Service定义：

### 示例1：

##### 使用ClusterIP的类型来创建一个service：

ClusterIP：默认，分配一个集群内部可以访问的虚拟IP（VIP）

vim service.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: default
spec:
  clusterIP: 10.0.0.123
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
```

文件注解如下：

```
apiVersion: v1		#api版本，决定了那个资源对象在API版本下
kind: Service		#绑定资源对象：Service
metadata: 				#源数据，指定service的名称和命名空间
  name: my-service		#service的名称
  namespace: default	#service的命名空间
spec:	#定义service：clusterIP、指定端口名称，service端口号、protocol协议，targetPort容器端口，和标签选择器的标签
  clusterIP: 10.0.0.123		 #service默认使用cluster的ip，为cluster分配一个IP，如果不指定会默认分配一个随机的IP 
  ports:
  - name: http			#指定端口的名称
    port: 80			#service端口
    protocol: TCP		#service协议
    targetPort: 80		#Pod容器端口
  selector:				#service通过标签选择器标签来关联后端的Pod	  
    app: nginx			#定义的标签，可用ubectl get pod -l app=nginx查看关联的Pod
```

查看刚刚创建的service：

kubectl get svc|grep my-service

```
[root@MASTER-1 demo2]# kubectl get svc my-service
NAME            TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
my-service     ClusterIP   10.0.0.123   <none>        80/TCP         11m
#可以看到service的类型是ClusterIP；
```

service创建要想动态感知后端的IP的变化还需要用到endpoints控制器：每个service会对应一个endpoints控制器

由endpoints关联后端的Pod，所以每个service都会关联有一个endpoints

kubectl get  ep					#ep 是endpoints的缩写

```
[root@MASTER-1 demo2]# kubectl get ep
NAME           ENDPOINTS                                      AGE
kubernetes     192.168.83.141:6443                            25d
my-service     172.17.26.2:80                                 16m
nginx-proxy    172.17.79.3:80,172.17.79.4:80,172.17.79.5:80   21d
nginx-server   172.17.79.3:80,172.17.79.4:80,172.17.79.5:80   21d
```

查看关联后端标签的Pod：

kubectl get pod -l  app=nginx		#也可以加：-o wide  查看更详细的信息，可以看到宿主机的IP和容器的IP

```
[root@MASTER-1 demo2]# kubectl get pod -l app=nginx
NAME         READY   STATUS    RESTARTS   AGE
nginx-test   1/1     Running   15         12d
```

如上所示查看到了关于nginx标签的Pod，这个Pod的IP就是上面my-service关联endpoints的IP地址

-------------------------------

#### Pod与Service的关系

service是通过selector标签选择器来关联后端的pod的

```
•通过label-selector相关联
•通过Service实现Pod的负载均衡（TCP/UDP 4层）默认是rr轮询方式
```

---------------------

### 示例2：

##### 使用NodePort的类型来创建

NodePort：在每个Node上分配一个端口作为外部访问入口

vim  service-NodePort.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: default
spec:
  type: NodePort		#设置类型为：NodePort
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 30008		#指定service的NodePort端口，默认是随机分配的端口
  selector:
    app: nginx
```

查看刚创建的service类型为NodePort的service

kubectl get svc my-service

```
[root@MASTER-1 demo2]# kubectl get svc my-service  
NAME         TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
my-service   NodePort   10.0.0.79    <none>        80:38582/TCP   7m31s
#可以看到上面service的类型是：NodePort,不管任何类型默认都会随机分配一个clusterIP，如NodePort的类型默认会起一个外部服务端口，这里默认分配的端口是：38582，会在每台Node上监听这个端口，用户可以通过Node的IP加端口38582访问Pod应用，访问一组Pod中的其中一个Pod使用了轮询的策略，部署集群时使用的是iptables来实现流量转发和负载均衡的，可以通过ipvsadm来查看生成的规则；
```

查看刚刚创建的service的详细配置：

kubectl get svc my-service -o yaml

```
apiVersion: v1
kind: Service
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"my-service","namespace":"default"},"spec":{"ports":[{"name":"http","port":80,"protocol":"TCP","targetPort":80}],"selector":{"app":"nginx"},"type":"NodePort"}}
  creationTimestamp: 2019-12-04T14:10:58Z
  name: my-service
  namespace: default
  resourceVersion: "390095"
  selfLink: /api/v1/namespaces/default/services/my-service
  uid: e53ea0cb-169f-11ea-9de9-000c29100356
spec:
  clusterIP: 10.0.0.79
  externalTrafficPolicy: Cluster
  ports:
  - name: http
    nodePort: 38582
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
  sessionAffinity: None
  type: NodePort
status:
  loadBalancer: {}
```

第三种类型：LoadBalancer：工作在特定的Cloud Provider上，例如Google Cloud，AWS，OpenStack，适用于云服务商；

#### 补充：

ClusterIP在部署集群时在apiserver中指定的：

查看apiserver的配置文件

 cat /opt/kubernetes/cfg/kube-apiserver

```
[root@MASTER-1 demo2]# cat /opt/kubernetes/cfg/kube-apiserver 

KUBE_APISERVER_OPTS="--logtostderr=true \
--v=4 \
--etcd-servers=https://192.168.83.141:2379,https://192.168.83.142:2379,https://192.168.83.143:2379 \
--bind-address=192.168.83.141 \
--secure-port=6443 \
--advertise-address=192.168.83.141 \
--allow-privileged=true \
--service-cluster-ip-range=10.0.0.0/24 \	#这里就是指定service集群IP的
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction \
--authorization-mode=RBAC,Node \
--kubelet-https=true \
--enable-bootstrap-token-auth \
--token-auth-file=/opt/kubernetes/cfg/token.csv \
--service-node-port-range=30000-50000 \		#设置了service的NodePort范围，默认是在这个范围内随机生成的
--tls-cert-file=/opt/kubernetes/ssl/server.pem  \
--tls-private-key-file=/opt/kubernetes/ssl/server-key.pem \
--client-ca-file=/opt/kubernetes/ssl/ca.pem \
--service-account-key-file=/opt/kubernetes/ssl/ca-key.pem \
--etcd-cafile=/opt/etcd/ssl/ca.pem \
--etcd-certfile=/opt/etcd/ssl/server.pem \
--etcd-keyfile=/opt/etcd/ssl/server-key.pem"
```



------------------------------

## 总结：

service的三种类型：

ClusterIP：默认，分配一个集群内部可以访问的虚拟IP（VIP）

NodePort：在每个Node上分配一个端口作为外部访问入口

// NodePort访问流程：用户 ----> 域名 ---> 负载均衡----> NodeIP：Port---> PodIP：Port

LoadBalancer：工作在特定的Cloud Provider上，例如Google Cloud，AWS，OpenStack

----------------------------------------------

## Service代理模式：

#### service代理模式有两种：

1、iptables

2、IPVS

service 代理是通过Node节点的kube-proxy来工作的，可以通过kube-proxy配置文件查看用的是哪种模式；

##### 查看kube-proxy配置文件：

cat /opt/kubernetes/cfg/kube-proxy

```
[root@NODE-2 ~]# cat /opt/kubernetes/cfg/kube-proxy
KUBE_PROXY_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=192.168.83.143 \
--cluster-cidr=10.0.0.0/24 \
--proxy-mode=ipvs \					#这里采用的是IPVS的代理模式；
--masquerade-all=true \				#这里是开启IPVS模式，去掉这两行就是iptables模式了；
--ipvs-scheduler=wrr  \				#设置ipvs的调度算法，默认为rr轮询；（一般无需修改）
--kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig"
```

##### ipvs支持的算法有：rr，wrr，lc，wlc，ip hash...  （--ipvs-scheduler=wrr ）

##### iptables模式可以使用：iptables-save |more 命令来查看规则；

##### ipvs是工作在内核，性能方面要比iptables高很多；

--------------------------

## DNS

DNS服务监视Kubernetes API，为每一个Service创建DNS记录用于域名解析

##### 创建DNS配置文件获取如下：

```
DNS配置文件：https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns/coredns  
我们只要使用：coredns.yaml.sed文件即可
```

coredns.yaml.sed文件内容如下：

```
# Warning: This is a file generated from the base underscore template file: coredns.yaml.base

apiVersion: v1
kind: ServiceAccount
metadata:
  name: coredns
  namespace: kube-system
  labels:
      kubernetes.io/cluster-service: "true"
      addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    addonmanager.kubernetes.io/mode: Reconcile
  name: system:coredns
rules:
- apiGroups:
  - ""
  resources:
  - endpoints
  - services
  - pods
  - namespaces
  verbs:
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    addonmanager.kubernetes.io/mode: EnsureExists
  name: system:coredns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:coredns
subjects:
- kind: ServiceAccount
  name: coredns
  namespace: kube-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
  labels:
      addonmanager.kubernetes.io/mode: EnsureExists
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {  #修改kubelet.config配置文件中指定的域，这里指定的是：cluster.local  
            pods insecure
            upstream
            fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        proxy . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "CoreDNS"
spec:
  # replicas: not specified here:
  # 1. In order to make Addon Manager do not reconcile this replicas parameter.
  # 2. Default is 1.
  # 3. Will be tuned in real time if DNS horizontal auto-scaling is turned on.
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
      annotations:
        seccomp.security.alpha.kubernetes.io/pod: 'docker/default'
    spec:
      serviceAccountName: coredns
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      containers:
      - name: coredns
        image: coredns/coredns:1.2.2		#DNS的镜像
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
          readOnly: true
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9153
          name: metrics
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - all
          readOnlyRootFilesystem: true
      dnsPolicy: Default
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
            - key: Corefile
              path: Corefile
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  annotations:
    prometheus.io/port: "9153"
    prometheus.io/scrape: "true"
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "CoreDNS"
spec:
  selector:
    k8s-app: kube-dns
  clusterIP: 10.0.0.2 	#修改kubelet.config 指定的集群IP地址即可
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
    
    #此配置文件中只需要修改三处：
    1、kubelet.config配置文件中指定的域
    2、kubelet.config配置文件中指定的clusterIP；
    3、镜像地址改为：coredns/coredns:1.2.2  即可；
```

### 执行创建DNS：

kubectl apply -f coredns.yaml

```
[root@MASTER-1 ~]# kubectl apply -f coredns.yaml 
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.extensions/coredns created
service/kube-dns created
```

##### 查看刚刚创建的DNS的Pod是否运行正常：

 kubectl get pods -n kube-system		#因为配置文件中指定了命名空间所以这里也要指定；

```
[root@MASTER-1 ~]# kubectl get pods -n kube-system
NAME                                    READY   STATUS    RESTARTS   AGE
coredns-56684f94d6-557xn                1/1     Running   0          70s
kubernetes-dashboard-7dffbccd68-swcjx   1/1     Running   22         16d
```

测试DNS是否正常：

先启动一个busybox来测试：

kubectl run -it --image=busybox:1.28.4 --rm --restart=Never sh   #创建一个Pod并进入到Pod里面， --rm 是退出即删除此Pod， --restart=Never  正常退出不重启；注意：busybox的镜像一定要用1.28.4版本，最新版本是有问题的；

```
[root@MASTER-1 ~]# kubectl run -it --image=busybox:1.28.4 --rm --restart=Never sh
If you don't see a command prompt, try pressing enter.
/ # 
```

测试一下解析：kubernetes默认的这个service

```
[root@MASTER-1 ~]# kubectl run -it --image=busybox:1.28.4 --rm --restart=Never sh
If you don't see a command prompt, try pressing enter.
/ # nslookup kubernetes		#解析service的名称为：kubernetes
Server:    10.0.0.2		#请求的地址，就是刚刚部署的coreDNS的地址；
Address 1: 10.0.0.2 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.0.0.1 kubernetes.default.svc.cluster.local	#解析出来的地址：10.0.0.1
/ # nslookup my-service			#解析service的名称为：my-service
Server:    10.0.0.2		#请求的地址，就是刚刚部署的coreDNS的地址；
Address 1: 10.0.0.2 kube-dns.kube-system.svc.cluster.local

Name:      my-service
Address 1: 10.0.0.79 my-service.default.svc.cluster.local	#解析出来的地址：10.0.0.79
/ # 
```

```
DNS服务监视Kubernetes API，为每一个Service创建DNS记录用于域名解析。

ClusterIP A记录格式：<service-name>.<namespace-name>.svc.cluster.local
示例：my-svc.my-namespace.svc.cluster.local

A记录示例：my-service.default.svc.cluster.local
```

#### 跨命名空间解析：即两个Pod在不同命名空间下解析：

##### 这里在创建一个busybox指定在kube-system命名空间下来做测试：

kubectl run -it --image=busybox:1.28.4 --rm --restart=Never sh -n kube-system

##### 下面来解析default命名空间下的my-service：

```
[root@MASTER-1 ~]# kubectl run -it --image=busybox:1.28.4 --rm --restart=Never sh -n kube-system
If you don't see a command prompt, try pressing enter.
/ # nslookup my-service.default	#只要在service名称后面加上.default即可解析default命名空间的服务，如果不加命名空间默认是解析当前命名空间的服务
Server:    10.0.0.2		#请求的地址
Address 1: 10.0.0.2 kube-dns.kube-system.svc.cluster.local	

Name:      my-service.default	#即是：servicename.namespace 即可
Address 1: 10.0.0.79 my-service.default.svc.cluster.local #解析到的IP地址：10.0.0.79；
/ # 
```

