# Kubernetes平台中日志收集

需要收集那些日志：

​	1、K8S系统的组件日志

​	2、K8S Cluster里面部署的应用程序日志

日志收集方案：Filebeat+ELK

LogFile——>Filebeat——>Logstash——>ES数据库——>Kibana

收集容器的日志：

默认情况下Node节中docker的容器标准输出日志会保存在：/var/lib/docker/containers 目录下，另外K8S也会将容器的日志保存一份在/var/log/containers目录中，以Pod名称开头命名的log文件；

收集容器日志有如下三种方案：

```
方案一：Node上部署一个日志收集程序
•DaemonSet方式部署日志收集程序
•对本节点/var/log和/var/lib/docker/containers/两个目录下的日志进行采集
```

![1576761583927](F:\文档笔记\Kubernetes\1576761583927.png)



```
方案二：Pod中附加专用日志收集的容器
•每个运行应用程序的Pod中增加一个日志收集容器，使用emtyDir共享日志目录让日志收集程序读取到。
```

![1576761647341](F:\文档笔记\Kubernetes\1576761647341.png)

```
方案三：应用程序直接推送日志
•超出Kubernetes范围
```

![1576761671213](F:\文档笔记\Kubernetes\1576761671213.png)



三个方案的优缺点：

| 方式                                | 优点                                                       | 缺点                                                         |
| :---------------------------------- | :--------------------------------------------------------- | :----------------------------------------------------------- |
| 方案一：Node上部署一个日志收集程序  | 每个Node仅需部署一个日志收集程序，资源消耗少，对应用无侵入 | 应用程序日志需要写到标准输出和标准错误输出，不支持多行日志   |
| 方案二：Pod中附加专用日志收集的容器 | 低耦合                                                     | 每个Pod启动一个日志收集代理，增加资源消耗，并增加运维维护成本 |
| 方案三：应用程序直接推送日志        | 无需额外收集工具                                           | 浸入应用，增加应用复杂度                                     |

本次采用方案二为实例演示；

--------------------

安装ELK：

这里只用yum来安装：

vim  /etc/yum.repos.d/elastic.repo

```
[logstash-6.x]
name=Elastic repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
~            
```

执行安装命令：

yum install logstash elasticsearch kibana -y

修改kibana配置文件：

vim  /etc/kibana/kibana.yaml

```
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
#修改以上三处即可；
```

修改elasticsearch.yaml

vim /etc/elasticsearch.yaml

```
path.data: /var/lib/elasticsearch		#默认数据目录，可根据需求修改
path.logs: /var/log/elasticsearch		#默认日志目录，可根据需求修改
network.host: 0.0.0.0
http.port: 9200
```

启动：elasticsearch和kibana

systemctl  start  elasticsearch

systemctl   start  kibana

在浏览器打开kibana：http://192.168.83.143:5601

logstash部分：

创建编写logstash配置文件：

vim  /etc/logstash/conf.d/logstash_to_es.conf  

```
input {
  beats {
    port => 5044

  }

}

filter {

}

output {
  elasticsearch {
     hosts => ["http://127.0.0.1:9200"]
     index => "k8s-log-%{+YYYY.MM.dd}"
  }
  stdout { codec => rubydebug  }
  
  #logstash配置文件分三部分：
  1、input阶段：数据从哪里来
  2、filter阶段：如何处理这些数据
  3、output阶段：输出到哪里存储
```

--------------------

部署k8s日志收集的Pod应用部署起来

vim  k8s-logs.yaml 

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: k8s-logs-filebeat-config
  namespace: kube-system 
  
data:
  filebeat.yml: |-
    filebeat.prospectors:
      - type: log
        paths:
          - /messages
        fields:
          app: k8s 
          type: module 
        fields_under_root: true

    output.logstash:
      hosts: ['192.168.83.143:5044']

---

apiVersion: apps/v1
kind: DaemonSet 
metadata:
  name: k8s-logs
  namespace: kube-system
spec:
  selector:
    matchLabels:
      project: k8s 
      app: filebeat
  template:
    metadata:
      labels:
        project: k8s
        app: filebeat
    spec:
      containers:
      - name: filebeat
        image: docker.elastic.co/beats/filebeat:6.4.2
        args: [
          "-c", "/etc/filebeat.yml",
          "-e",
        ]
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
          limits:
            cpu: 500m
            memory: 500Mi
        securityContext:
          runAsUser: 0
        volumeMounts:
        - name: filebeat-config
          mountPath: /etc/filebeat.yml
          subPath: filebeat.yml
        - name: k8s-logs 
          mountPath: /messages
      volumes:
      - name: k8s-logs
        hostPath: 
          path: /var/log/messages
          type: File
      - name: filebeat-config
        configMap:
          name: k8s-logs-filebeat-config

```

启动logstash：

/usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/logstash_to_es.conf 

-----------------------

执行kubectl部署：

kubectl  apply  -f   k8s-logs.yaml 

查看刚部署的Pod

kubectl get pods -n kube-system

```
[root@MASTER-1 logs]# kubectl get pods -n kube-system
NAME                                    READY   STATUS    RESTARTS   AGE
coredns-56684f94d6-557xn                1/1     Running   14         15d
heapster-66687b8845-bzj85               1/1     Running   2          43h
k8s-logs-dtcmd                          1/1     Running   0          3m39s	#刚部署得pod
k8s-logs-t7dzr                          1/1     Running   0          3m39s  #刚部署得pod
kubernetes-dashboard-7dffbccd68-mtrmm   1/1     Running   1          25h
monitoring-grafana-cd8b89587-2m54k      1/1     Running   2          42h
monitoring-influxdb-864c767966-ft4mz    1/1     Running   1          25h
#看到有两个k8s-logs的pod，因为有两台Node 所以会起两个Pod
```

 可以进入到Pod查看下挂载的目录：

kubectl exec -it k8s-logs-dtcmd /bin/bash -n kube-system

登录进去之后查看挂载的目录是否有数据：

more  /messages		#因为上面的yaml文件挂载的是/messages, 有数据表示正常；

-------------------------------------

登录kibana配置索引：

management——>index patterns——>Create index pattern——index pattern

在kibana上面能看到k8s-log的日志表示正常

-------------------------

收集应用的日志，以nginx为例：

 

