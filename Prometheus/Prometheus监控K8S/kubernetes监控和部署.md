

# kubernetes监控部署

#### kubernetes监控方案：cAdvisor/exporter+Prometheus+Grafana

| 监控指标        | 工具插件           | 监控资源举例           |
| --------------- | ------------------ | ---------------------- |
| Pod监控         | cAdvisor           | 容器CPU，内存利用率    |
| Node监控        | node-exporter      | 节点CPU，内存利用率    |
| K8S资源对象监控 | kube-state-metrics | Pod/Deployment/Service |

#### 在k8s中部署一套Prometheus监控然后对k8s个组件指标进行监控

### 1、创建一个rbac授权：

```
vim prometheus-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: prometheus
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile 
rules:					#授予的权限
  - apiGroups:
      - ""
    resources:
      - nodes
      - nodes/metrics
      - services
      - endpoints
      - pods
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - get
  - nonResourceURLs:
      - "/metrics"
    verbs:
      - get
---
apiVersion: rbac.authorization.k8s.io/v1beta1		#角色绑定
kind: ClusterRoleBinding
metadata:
  name: prometheus
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: kube-system
 ------------------------------------------------------------------------------
  创建：kubectl apply -f prometheus-rbac.yaml
```

### 2、创建一个configmap

```
vim prometheus-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: kube-system 
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: EnsureExists
data:
  prometheus.yml: |					#Prometheus配置和采集的目标
    rule_files:			#配置读取rules的配置
    - /etc/config/rules/*.rules		#rules配置的存放目录

    scrape_configs:
    - job_name: prometheus
      static_configs:
      - targets:
        - localhost:9090

    - job_name: kubernetes-nodes
      scrape_interval: 30s
      static_configs:
      - targets:
        - 192.168.83.142:9100
        - 192.168.83.143:9100

    - job_name: kubernetes-apiservers	#配置采集apiserver的指标
      kubernetes_sd_configs:			#基于kubernetes的服务发现配置
      - role: endpoints
      relabel_configs:					#重写标签配置
      - action: keep					#只保留正则匹配的标签
        regex: default;kubernetes;https	#源标签的值包含这三个值，只采集这几个包含的
        source_labels:
        - __meta_kubernetes_namespace
        - __meta_kubernetes_service_name
        - __meta_kubernetes_endpoint_port_name
      scheme: https						#采集方式是：https
      tls_config:    #prometheus访问apiserver使用的ca和token，创建一个容器默认会分配这两个授权文件
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true  #跳过https认证，直接只用token来认证；
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token	
 
    - job_name: kubernetes-nodes-kubelet	#采集nodes-kubelet
      kubernetes_sd_configs:
      - role: node			#角色node
      relabel_configs:		#重写标签配置
      - action: labelmap	
        regex: __meta_kubernetes_node_label_(.+)
      scheme: https			#采集方式是：https   
      tls_config:			#与上面是一样的方式
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

    - job_name: kubernetes-nodes-cadvisor	#监控采集nodes-cadvisor
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __metrics_path__		#默认源标签
        replacement: /metrics/cadvisor  	#重新定义默认采集接口的地址标签
      scheme: https			 #采集方式是：https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

    - job_name: kubernetes-service-endpoints	#采集service-endpoints
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - action: keep	#只保留下面的源标签的值，只采集目标中的源标签，包含下面这些；
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scrape
      - action: replace
        regex: (https?)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scheme
        target_label: __scheme__
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_path
        target_label: __metrics_path__	#接口地址metrics，如果是其他的接口地址也可以在这里修改
      - action: replace			
        regex: ([^:]+)(?::\d+)?;(\d+)	#正则匹配
        replacement: $1:$2				#$1是IP，$2是端口
        source_labels:
        - __address__		#将IP赋予address
        - __meta_kubernetes_service_annotation_prometheus_io_port #将端口赋予采集端口
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - action: replace
        source_labels:	#将__meta_kubernetes_namespace命名空间标记为：kubernetes_namespace
        - __meta_kubernetes_namespace
        target_label: kubernetes_namespace	#命名空间标记为：kubernetes_namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_service_name	#采集的service名称
        target_label: kubernetes_name		#标记service名称为：kubernetes_name

    - job_name: kubernetes-services		#采集kubernetes-services任务，探测IP和端口是否可用
      kubernetes_sd_configs:
      - role: service
      metrics_path: /probe			#探测的路径
      params:
        module:
        - http_2xx					#探测使用的模块
      relabel_configs:
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_probe
      - source_labels:
        - __address__
        target_label: __param_target
      - replacement: blackbox		#使用Prometheus的blackbox组件来探测
        target_label: __address__
      - source_labels:
        - __param_target
        target_label: instance
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels:
        - __meta_kubernetes_namespace
        target_label: kubernetes_namespace
      - source_labels:
        - __meta_kubernetes_service_name
        target_label: kubernetes_name

    - job_name: kubernetes-pods		#采集kubernetes-pods
      kubernetes_sd_configs:
      - role: pod			#角色pod
      relabel_configs:
      - action: keep	#只保留下面的源标签的值，只采集下面这些源标签的值；
        regex: true
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_scrape
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_path
        target_label: __metrics_path__
      - action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        source_labels:
        - __address__
        - __meta_kubernetes_pod_annotation_prometheus_io_port
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: kubernetes_namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: kubernetes_pod_name
    alerting:		#告警配置，将告警发送给alertmanager
      alertmanagers:
      - static_configs:
          - targets: ["alertmanager:80"] #这里是配置Prometheus与alertmanager通信的，由于使用了k8s内部DNS所以直接写服务名，配置完成后可以在Prometheus后台web端的Configuration中可以看到；
         
--------------------------------------------------------------------------------------
创建：kubectl apply -f prometheus-configmap.yaml

```

### 3、创建Prometheus有状态部署

#### 动态创建PV

```
vim prometheus-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: prometheus 
  namespace: kube-system
  labels:
    k8s-app: prometheus
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    version: latest
spec:
  serviceName: "prometheus"
  replicas: 1
  podManagementPolicy: "Parallel"
  updateStrategy:
   type: "RollingUpdate"
  selector:
    matchLabels:
      k8s-app: prometheus
  template:
    metadata:
      labels:
        k8s-app: prometheus
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      priorityClassName: system-cluster-critical
      serviceAccountName: prometheus
      initContainers:				#初始化容器
      - name: "init-chown-data"
        image: "busybox:latest"
        imagePullPolicy: "IfNotPresent"
        command: ["chown", "-R", "65534:65534", "/data"]   #赋予Prometheus的数据目录权限
        volumeMounts:
        - name: prometheus-data
          mountPath: /data
          subPath: ""
      containers:
        - name: prometheus-server-configmap-reload	#容器名称
          image: "jimmidyson/configmap-reload:v0.1"	#此容器用作于对Prometheus的configmap配置有改动是进行重新加载
          imagePullPolicy: "IfNotPresent"
          args:
            - --volume-dir=/etc/config
            - --webhook-url=http://localhost:9090/-/reload
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
              readOnly: true
          resources:
            limits:
              cpu: 10m
              memory: 10Mi
            requests:
              cpu: 10m
              memory: 10Mi

        - name: prometheus-server				#Prometheus容器名称
          image: "prom/prometheus:latest"		#Prometheus镜像
          imagePullPolicy: "IfNotPresent"		#拉取策略
          args:
            - --config.file=/etc/config/prometheus.yml
            - --storage.tsdb.path=/data
            - --web.console.libraries=/etc/prometheus/console_libraries
            - --web.console.templates=/etc/prometheus/consoles
            - --web.enable-lifecycle
          ports:
            - containerPort: 9090
          readinessProbe:		#健康检查
            httpGet:
              path: /-/ready
              port: 9090
            initialDelaySeconds: 30
            timeoutSeconds: 30
          livenessProbe:
            httpGet:
              path: /-/healthy
              port: 9090
            initialDelaySeconds: 30
            timeoutSeconds: 30
          # based on 10 running nodes with 30 pods each
          resources:
            limits:
              cpu: 200m
              memory: 1000Mi
            requests:
              cpu: 200m
              memory: 1000Mi
            
          volumeMounts:				#数据卷
            - name: config-volume
              mountPath: /etc/config		#动态pv挂载的目录
            - name: prometheus-data
              mountPath: /data				#动态pv的数据目
              subPath: ""
            #- name: prometheus-rules  #这里是配置configmap挂载到容器rules目录，这个名称在prometheus-rules文件metadata:中定义的，名称一定要一致，否则会找不到这个configmap，先注释掉，等部署完prometheus-rules在开启否则会提示找不到prometheus-rules
            #  mountPath: /etc/config/rules

      terminationGracePeriodSeconds: 300
      volumes:
        - name: config-volume
          configMap:
            name: prometheus-config
        #- name: prometheus-rules	 #这里是配置configmap挂载到容器rules目录，这个名称在prometheus-rules文件metadata:中定义的，名称一定要一致，否则会找不到这个configmap，先注释掉，等部署完prometheus-rules在开启否则会提示找不到prometheus-rules
        #  configMap:
        #    name: prometheus-rules

  volumeClaimTemplates:
  - metadata:
      name: prometheus-data
    spec:
      storageClassName: managed-nfs-storage  #填写存储的名称，使用动态pv,自动创建pv
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: "16Gi"
----------------------------------------------------------------------------------
创建: kubectl apply -f prometheus-statefulset.yaml  
默认会启动两个容器：
1、jimmidyson/configmap-reload:v0.1
#此容器用作于对Prometheus的configmap配置有改动是进行重新加载
2、prom/prometheus:latest
#此容器是Prometheus的容器
-----------------------------------------------------------------------------------        #这里使用的是NFS存储：
[root@MASTER-1 prometheus-k8s]# kubectl get storageclass
NAME                  PROVISIONER      AGE
managed-nfs-storage   fuseim.pri/ifs   100d
```

#### 静态创建PV		（动态和静态二选一即可）

```
apiVersion: v1
kind: PersistentVolumeClaim			#资源对象：PVC
metadata:
  name: prometheus-data				#这个PVC的名称需要在底部的claimName中指定
  namespace: kube-system
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 16Gi
---
#创建PV
apiVersion: v1	
kind: PersistentVolume
metadata:
  name: pv0001				#创建PV的名字
spec:
  capacity:
    storage: 16Gi			#创建PV的存储空间是16G
  accessModes:				#定义模式
    - ReadWriteOnce			#定义为读写模式
  nfs:						#采用NFS存储
    path: /data/nfs/prometheus_data			#挂载的目录，创建PV前必须在NFS服务器创建这个目录
    server: 192.168.83.143	#NFS服务器地址
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: prometheus 
  namespace: kube-system
  labels:
    k8s-app: prometheus
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    version: v2.2.1
spec:
  serviceName: "prometheus"
  replicas: 1
  podManagementPolicy: "Parallel"
  updateStrategy:
   type: "RollingUpdate"
  selector:
    matchLabels:
      k8s-app: prometheus
  template:
    metadata:
      labels:
        k8s-app: prometheus
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      priorityClassName: system-cluster-critical
      serviceAccountName: prometheus
      initContainers:
      - name: "init-chown-data"
        image: "busybox:latest"
        imagePullPolicy: "IfNotPresent"
        command: ["chown", "-R", "65534:65534", "/data"]
        volumeMounts:
        - name: prometheus-data
          mountPath: /data
          subPath: ""
      containers:
        - name: prometheus-server-configmap-reload
          image: "jimmidyson/configmap-reload:v0.1"
          imagePullPolicy: "IfNotPresent"
          args:
            - --volume-dir=/etc/config
            - --webhook-url=http://localhost:9090/-/reload
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
              readOnly: true
          resources:
            limits:
              cpu: 10m
              memory: 10Mi
            requests:
              cpu: 10m
              memory: 10Mi

        - name: prometheus-server
          image: "prom/prometheus:v2.2.1"
          imagePullPolicy: "IfNotPresent"
          args:
            - --config.file=/etc/config/prometheus.yml
            - --storage.tsdb.path=/data
            - --web.console.libraries=/etc/prometheus/console_libraries
            - --web.console.templates=/etc/prometheus/consoles
            - --web.enable-lifecycle
          ports:
            - containerPort: 9090
          readinessProbe:
            httpGet:
              path: /-/ready
              port: 9090
            initialDelaySeconds: 30
            timeoutSeconds: 30
          livenessProbe:
            httpGet:
              path: /-/healthy
              port: 9090
            initialDelaySeconds: 30
            timeoutSeconds: 30
          # based on 10 running nodes with 30 pods each
          resources:
            limits:
              cpu: 200m
              memory: 1000Mi
            requests:
              cpu: 200m
              memory: 1000Mi
            
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
            - name: prometheus-data
              mountPath: /data
              subPath: ""
            #- name: prometheus-rules    #这里是配置configmap挂载到容器rules目录，这个名称在prometheus-rules文件metadata:中定义的，名称一定要一致，否则会找不到这个configmap，先注释掉，等部署完prometheus-rules在开启否则会提示找不到prometheus-rules
            #  mountPath: /etc/config/rules

      terminationGracePeriodSeconds: 300
      volumes:
        - name: config-volume
          configMap:
            name: prometheus-config
        #- name: prometheus-rules	 #这里是配置configmap挂载到容器rules目录，这个名称在prometheus-rules文件metadata:中定义的，名称一定要一致，否则会找不到这个configmap，先注释掉，等部署完prometheus-rules在开启否则会提示找不到prometheus-rules
        #  configMap:
        #    name: prometheus-rules
        - name: prometheus-data		#需要静态的去指定PVC
          persistentVolumeClaim:
            claimName: prometheus-data		#指定PVC的名字叫：prometheus-data
            
------------------------------------------------------------------------------
创建：kubectl apply -f prometheus-statefulset-static-pv.yaml 
```



### 创建Prometheus的service

```
vim prometheus-service.yaml
kind: Service
apiVersion: v1
metadata: 
  name: prometheus
  namespace: kube-system
  labels: 
    kubernetes.io/name: "Prometheus"
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
spec: 
  type: NodePort	#使用NodePort发布类型
  ports: 		#指定内部访问的协议和端口
    - name: http 
      port: 9090
      protocol: TCP
      targetPort: 9090
  selector: 	#标签选择器
    k8s-app: prometheus		#匹配StatefulSet上面的标签
 -----------------------------------------------------------------------------------
 创建：kubectl apply -f prometheus-service.yaml
```

查看刚刚创建的pod和service，存放在kube-system命名空间下：

```
kubectl get pod,svc -n kube-system
-------------------------------------------------------
[root@MASTER-1 prometheus-k8s]# kubectl get pod,svc -n kube-system
NAME                                        READY   STATUS    RESTARTS   AGE
pod/coredns-56684f94d6-557xn                1/1     Running   29         111d
pod/heapster-66687b8845-bzj85               1/1     Running   17         97d
pod/k8s-logs-dtcmd                          1/1     Running   15         96d
pod/k8s-logs-t7dzr                          1/1     Running   13         96d
pod/kubernetes-dashboard-7dffbccd68-mtrmm   1/1     Running   16         97d
pod/monitoring-grafana-cd8b89587-2m54k      1/1     Running   17         97d
pod/monitoring-influxdb-864c767966-ft4mz    1/1     Running   16         97d
pod/prometheus-0                            2/2     Running   0          14m

NAME                           TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
service/heapster               ClusterIP   10.0.0.29    <none>        80/TCP           97d
service/kube-dns               ClusterIP   10.0.0.2     <none>        53/UDP,53/TCP    111d
service/kubernetes-dashboard   NodePort    10.0.0.50    <none>        443:30001/TCP    135d
service/monitoring-grafana     NodePort    10.0.0.55    <none>        80:33617/TCP     97d
service/monitoring-influxdb    ClusterIP   10.0.0.234   <none>        8086/TCP         97d
service/prometheus             NodePort    10.0.0.71    <none>        9090:37233/TCP   94m
#Prometheus内部访问端口：9090
#Prometheus对外访问端口是：37233
```

#### 查看PV和PVCz状态：

```
kubectl get  pv,pvc -n kube-system
```

![1585216789790](https://note.youdao.com/yws/api/personal/file/6080D89A026D45818524E165C2585321?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

最后查看运行状态：

```
kubectl get pod,svc -n kube-system
```

![1585217593340](https://note.youdao.com/yws/api/personal/file/5B73C21E86EF461ABC8258EA6A63FD07?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

##### 使用StatefulSet部署的容器第一个容器序号是0，Prometheus-0

进入Prometheus容器查看配置文件：

```
kubectl exec -it prometheus-0 sh -n kube-system -c prometheus-server
----------------
#-n  指定命名空间
#-c  指定进入哪个容器中
```

到此Prometheus监控就部署完成！

------------

# 监控POD集群

cAdvisor是用于采集pod的指标工具，而cAdvisor已经集成到kubelet中，所以无需单独安装cAdvisor，使用的端口是：10250，cAdvisor会采集所有容器pod的指标包括宿主机的资源指标，

暴露接口地址：

```
https://NodeIP:10255/metrics/cadvisor
https://NodeIP:10250/metrics/cadvisor
```

kubelet的配置文件内容：

```
[root@NODE-2 prometheus_data]# cat /opt/kubernetes/cfg/kubelet.config 

kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 192.168.83.143
port: 10250
readOnlyPort: 10255
cgroupDriver: cgroupfs
clusterDNS:
- 10.0.0.2 
clusterDomain: cluster.local.
failSwapOn: false
authentication:
  anonymous:
    enabled: true
```

也可以通过只读端口来访问：http://192.168.83.142:10255/metrics/cadvisor

-------------

### k8s中部署grafana

grafana部署文件：

```
vim grafana.yaml

apiVersion: apps/v1 
kind: StatefulSet 			#资源对象StatefulSet有状态应用部署
metadata:
  name: grafana
  namespace: kube-system		#使用了kube-system	命名空间
spec:
  serviceName: "grafana"
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana
        ports:
          - containerPort: 3000
            protocol: TCP
        resources:
          limits:
            cpu: 100m            
            memory: 256Mi          
          requests:
            cpu: 100m            
            memory: 256Mi
        volumeMounts:
          - name: grafana-data
            mountPath: /var/lib/grafana
            subPath: grafana
      securityContext:
        fsGroup: 472
        runAsUser: 472
  volumeClaimTemplates:		#使用功能了动态PV存储
  - metadata:
      name: grafana-data
    spec:
      storageClassName: managed-nfs-storage 	#存储class的名称，这里是NFS存储
      accessModes:			#访问模式	
        - ReadWriteOnce		#可读写
      resources:
        requests:
          storage: "2Gi"

---
#创建service
apiVersion: v1	
kind: Service
metadata:
  name: grafana
  namespace: kube-system
spec:
  type: NodePort
  ports:
  - port : 80
    targetPort: 3000				#内部访问端口
    nodePort: 30007					#对外暴露端口	
  selector:
    app: grafana
```

执行创建：kubectl apply -f  grafana.yaml

创建完成查看一下状态：

```
[root@MASTER-1 prometheus-k8s]# kubectl get pods,svc -n kube-system
NAME                                        READY   STATUS    RESTARTS   AGE
pod/coredns-56684f94d6-557xn                1/1     Running   30         112d
pod/grafana-0                               1/1     Running   0          79s
pod/heapster-66687b8845-bzj85               1/1     Running   18         98d
pod/k8s-logs-dtcmd                          1/1     Running   16         97d
pod/k8s-logs-t7dzr                          1/1     Running   15         97d
pod/kubernetes-dashboard-7dffbccd68-mtrmm   1/1     Running   17         98d
pod/monitoring-grafana-cd8b89587-2m54k      1/1     Running   18         98d
pod/monitoring-influxdb-864c767966-ft4mz    1/1     Running   17         98d
pod/prometheus-0                            2/2     Running   5          23h

NAME                           TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
service/grafana                NodePort    10.0.0.202   <none>        80:30007/TCP     81s
service/heapster               ClusterIP   10.0.0.29    <none>        80/TCP           98d
service/kube-dns               ClusterIP   10.0.0.2     <none>        53/UDP,53/TCP    112d
service/kubernetes-dashboard   NodePort    10.0.0.50    <none>        443:30001/TCP    136d
service/monitoring-grafana     NodePort    10.0.0.55    <none>        80:33617/TCP     98d
service/monitoring-influxdb    ClusterIP   10.0.0.234   <none>        8086/TCP         98d
service/prometheus             NodePort    10.0.0.71    <none>        9090:37233/TCP   26h
```

OK，看到没有问题就可以访问了：

打开浏览器访问：http://192.168.83.142:30007  

初始账号密码：admin 第一次访问会要求设置新的密码；

添加数据源，由于我们K8S中部署了DNS和grafana所以我们可以直接使用服务名来访问，DNS会自动解析；

![1585303114657](https://note.youdao.com/yws/api/personal/file/2DE2DA0D6C1B43C7A7CE703547E19414?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

接下来创建仪表盘和导入模板即可

推荐模板：

```
集群资源监控：3119
资源状态监控：6417
Node监控：9276
```

----------------

# 监控K8S资源对象

kube-state-metrics采集了k8s中各种资源对象的状态信息：

部署kube-state-metrics插件

主要采集如下信息：

```
kube_daemonset_*
kube_deployment_*
kube_job_*
kube_namespace_*
kube_node_*
kube_persistentvolumeclaim_*
kube_pod_container_*
kube_pod_*
kube_replicaset_*
kube_service_*
kube_statefulset_*
```

创建kube-state-metrics-rbac授权

```
vim kube-state-metrics-rbac.yml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-state-metrics
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-state-metrics
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
rules:
- apiGroups: [""]
  resources:
  - configmaps
  - secrets
  - nodes
  - pods
  - services
  - resourcequotas
  - replicationcontrollers
  - limitranges
  - persistentvolumeclaims
  - persistentvolumes
  - namespaces
  - endpoints
  verbs: ["list", "watch"]
- apiGroups: ["extensions"]
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs: ["list", "watch"]
- apiGroups: ["apps"]
  resources:
  - statefulsets
  verbs: ["list", "watch"]
- apiGroups: ["batch"]
  resources:
  - cronjobs
  - jobs
  verbs: ["list", "watch"]
- apiGroups: ["autoscaling"]
  resources:
  - horizontalpodautoscalers
  verbs: ["list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: kube-state-metrics-resizer
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
rules:
- apiGroups: [""]
  resources:
  - pods
  verbs: ["get"]
- apiGroups: ["extensions"]
  resources:
  - deployments
  resourceNames: ["kube-state-metrics"]
  verbs: ["get", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1 
kind: ClusterRoleBinding
metadata:
  name: kube-state-metrics
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-state-metrics
subjects:
- kind: ServiceAccount
  name: kube-state-metrics
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kube-state-metrics
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kube-state-metrics-resizer
subjects:
- kind: ServiceAccount
  name: kube-state-metrics
  namespace: kube-system

```

执行创建：kubectl apply -f kube-state-metrics-rbac.yaml

创建一个kube-state-metrics-deployment

```
vim kube-state-metrics-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-state-metrics
  namespace: kube-system
  labels:
    k8s-app: kube-state-metrics
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    version: v1.3.0
spec:
  selector:
    matchLabels:
      k8s-app: kube-state-metrics
      version: v1.3.0
  replicas: 1
  template:
    metadata:
      labels:
        k8s-app: kube-state-metrics
        version: v1.3.0
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      priorityClassName: system-cluster-critical
      serviceAccountName: kube-state-metrics
      containers:		#主容器kube-state-metrics
      - name: kube-state-metrics
        image: juestnow/kube-state-metrics:v1.8.0	#容器镜像
        ports:
        - name: http-metrics
          containerPort: 8080
        - name: telemetry
          containerPort: 8081
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          timeoutSeconds: 5
      - name: addon-resizer			#第二个容器，尚未知道作用，但是必须要有此容器
        image: juestnow/addon-resizer:1.8.5	
        resources:
          limits:
            cpu: 100m
            memory: 30Mi
          requests:
            cpu: 100m
            memory: 30Mi
        env:
          - name: MY_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: MY_POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
        volumeMounts:
          - name: config-volume
            mountPath: /etc/config
        command:
          - /pod_nanny
          - --config-dir=/etc/config
          - --container=kube-state-metrics
          - --cpu=100m
          - --extra-cpu=1m
          - --memory=100Mi
          - --extra-memory=2Mi
          - --threshold=5
          - --deployment=kube-state-metrics
      volumes:
        - name: config-volume
          configMap:
            name: kube-state-metrics-config
---
# Config map for resource configuration.
apiVersion: v1
kind: ConfigMap			#configmap，以后要添加配置就在这里添加
metadata:
  name: kube-state-metrics-config
  namespace: kube-system
  labels:
    k8s-app: kube-state-metrics
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
data:
  NannyConfiguration: |-
    apiVersion: nannyconfig/v1alpha1
    kind: NannyConfiguration
```

启动完之后到Prometheus后台查看一下数据

![1585558328310](https://note.youdao.com/yws/api/personal/file/2CFC16DB5093457981F8664DC95398E4?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

能看到数据证明是可以正常采集，接下来到grafana中引入模板

grafana模板资源状态监控：6417

--------------

# 在K8S中部署Alertmanager

#### 创建alertmanager-configmap

```
vim alertmanager-configmap.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: EnsureExists
data:		
  alertmanager.yml: |           #alertmanager告警配置
    global: 			#全局配置，配置发送邮件的服务器配置
      resolve_timeout: 5m
      smtp_smarthost: 'smtp.163.com:25'
      smtp_from: 'yhui8899@163.com'
      smtp_auth_username: 'yhui8899@163.com'
      smtp_auth_password: '123321'

    receivers:		#接收器，配置接收者的信息，这是邮件接收地址
    - name: default-receiver
      email_configs:
      - to: "355638930@qq.com"

    route:
      group_interval: 1m		#分组的间隔时间
      group_wait: 10s
      receiver: default-receiver
      repeat_interval: 1m		#发送重复邮件的间隔时间，建议调20或30分钟

```

执行部署：kubectl apply -f alertmanager-configmap.yaml 

#### 创建alertmanager-deployment

```
vim alertmanager-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alertmanager
  namespace: kube-system
  labels:
    k8s-app: alertmanager
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    version: v0.14.0
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: alertmanager
      version: v0.14.0
  template:
    metadata:
      labels:
        k8s-app: alertmanager
        version: v0.14.0
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
    spec:
      priorityClassName: system-cluster-critical
      containers:
        - name: prometheus-alertmanager #alertmanager容器名称
          image: "prom/alertmanager:v0.14.0"	#alertmanager镜像
          imagePullPolicy: "IfNotPresent"		
          args:
            - --config.file=/etc/config/alertmanager.yml	#主配置文件位置
            - --storage.path=/data			#存储数据位置，PVC挂载路径就是这里
            - --web.external-url=/
          ports:
            - containerPort: 9093
          readinessProbe:
            httpGet:
              path: /#/status
              port: 9093
            initialDelaySeconds: 30
            timeoutSeconds: 30
          volumeMounts:		#挂载
            - name: config-volume
              mountPath: /etc/config		#配置文件就是挂载到这个目录下
            - name: storage-volume			#存储卷
              mountPath: "/data"			#挂载目录
              subPath: ""
          resources:				#资源限制
            limits:
              cpu: 10m
              memory: 50Mi
            requests:
              cpu: 10m
              memory: 50Mi
        - name: prometheus-alertmanager-configmap-reload	#容器名称，当configmap配置文件更新后它会自动加载更新配置文件；
          image: "jimmidyson/configmap-reload:v0.1"		#configmap-reload镜像
          imagePullPolicy: "IfNotPresent"
          args:
            - --volume-dir=/etc/config
            - --webhook-url=http://localhost:9093/-/reload
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
              readOnly: true
          resources:
            limits:
              cpu: 10m
              memory: 10Mi
            requests:
              cpu: 10m
              memory: 10Mi
      volumes:					#数据卷引用
        - name: config-volume
          configMap:
            name: alertmanager-config			#主配置文件名称
        - name: storage-volume
          persistentVolumeClaim:
            claimName: alertmanager

```

执行部署： kubectl apply -f alertmanager-deployment.yaml

#### 创建alertmanager-pvc

```
vim alertmanager-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: alertmanager
  namespace: kube-system				
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: EnsureExists
spec:
  storageClassName: managed-nfs-storage 		#存储类，这里使用功能的是NFS
  accessModes:									#访问模式
    - ReadWriteOnce								#读写
  resources:
    requests:
      storage: "2Gi"							#存储大小2G

```

执行部署：kubectl apply -f alertmanager-pvc.yaml



#### 创建alertmanager-service

service主要是将alertmanager暴露出去，让其他组件可以调用

```
apiVersion: v1
kind: Service
metadata:
  name: alertmanager
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "Alertmanager"
spec:
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: 9093
  selector:
    k8s-app: alertmanager 
  type: "ClusterIP"				#使用集群内部IP

```

执行部署：kubectl apply -f alertmanager-service.yaml

配置Prometheus与Alertmanager通信，需要在Prometheus-configmap.yml配置文件中配置

### 配置告警：

##### 1、prometheus指定rules目录---此配置在Prometheus-configmap.yml配置文件中配置

##### 2、configmap存储告警规则

```
vim prometheus-rules.yml

apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules		
  namespace: kube-system
data:
  general.rules: |	#Prometheus-server容器中会生成一个以这个名称命名的文件
    groups:
    - name: general.rules
      rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: error 
        annotations:
          summary: "Instance {{ $labels.instance }} 停止工作"
          description: "{{ $labels.instance }} job {{ $labels.job }} 已经停止5分钟以上."
  node.rules: |
    groups:
    - name: node.rules		#Prometheus-server容器中会生成一个以这个名称命名的文件
      rules:
      - alert: NodeFilesystemUsage
        expr: 100 - (node_filesystem_free_bytes{fstype=~"ext4|xfs"} / node_filesystem_size_bytes{fstype=~"ext4|xfs"} * 100) > 80 
        for: 1m
        labels:
          severity: warning 
        annotations:
          summary: "Instance {{ $labels.instance }} : {{ $labels.mountpoint }} 分区使用率过高"
          description: "{{ $labels.instance }}: {{ $labels.mountpoint }} 分区使用大于80% (当前值: {{ $value }})"

      - alert: NodeMemoryUsage
        expr: 100 - (node_memory_MemFree_bytes+node_memory_Cached_bytes+node_memory_Buffers_bytes) / node_memory_MemTotal_bytes * 100 > 80
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Instance {{ $labels.instance }} 内存使用率过高"
          description: "{{ $labels.instance }}内存使用大于80% (当前值: {{ $value }})"

      - alert: NodeCPUUsage    
        expr: 100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100) > 60 
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Instance {{ $labels.instance }} CPU使用率过高"       
          description: "{{ $labels.instance }}CPU使用大于60% (当前值: {{ $value }})"

```

##### 3、configmap挂载到容器rules目录，在prometheus-statefulset-static-pv.yml中配置

配置启动完后可以访问Prometheus后台查看Alerts如下图：

![1585563049655](https://note.youdao.com/yws/api/personal/file/7F3083F5691E4EBB9B6C93B38884B03F?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

在Rules可以看到刚刚的那两个配置

![1585563113582](https://note.youdao.com/yws/api/personal/file/E8C22BB453164471A01D4B4C0D590269?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

这是我们刚刚在configmap中指定的



##### 4、增加alertmanager告警配置，在alertmanager-configmap.yml文件中配置

---------

查看Prometheus-rules生成的两个配置文件，在Prometheus-server中查看

进入Prometheus-server的pod中查看

```
kubectl exec -it prometheus-0 sh -n kube-system -c prometheus-server
```

![1585564219468](https://note.youdao.com/yws/api/personal/file/97BC3B8F48A8490493576909B032B196?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)