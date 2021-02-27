### kubectl命令行工具管理集群
**1、创建：**

```
kubectl run nginx --replicas=3 --image=nginx:1.14 --port=80

kubectl get deploy,pods

kubectl run nginx --image=nginx:latest --port=80 --replicas=3 --dry-run  -o yaml > my-deployment.yaml  #将命令导出生成为yaml格式文件
```
**注意**：使用kubectl run  创建的都是deployment状态

**2、发布:**

```
kubectl expose deployment nginx --port=80 --type=NodePort --target-port=80 --name=nginx-service

kubectl get service
```

**3、更新:**

```
kubectl set image deployment/nginx nginx=nginx:1.15
```

**4、回滚:**

```
kubectl rollout history deployment/nginx    #查看版本记录

kubectl rollout undo deployment/nginx		#回滚到上一个版本

kubectl rollout status deployment/nginx     #查看回滚状态

#kubectl  rollout --help 常用参数如下：

 history        #显示 rollout 历史
  pause         #标记提供的 resource 为中止状态
  resume        #继续一个停止的 resource
  status        #显示 rollout 的状态
  undo          #回滚到上一次的版本
```
**5、删除:**

```
kubectl delete deploy/nginx

kubectl delete svc/nginx-service
```
**6、查看帮助文档：**
```shell
kubectl explain pods.spec.containers    #查看Pod资源下的容器字段配置
```
------------------------------------------------------------------------------
### 常用命令

kubectl  get  pods,deploy,replicaset     #查看多个资源

```shell
[root@MASTER-1 ~]# kubectl get pods,deploy,replicaset
NAME                        READY   STATUS    RESTARTS   AGE
pod/nginx-dbddb74b8-x96v6   1/1     Running   2          24h

NAME                          DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/nginx   1         1         1            1           24h

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.extensions/nginx-dbddb74b8   1         1         1       24h
```

**创建一个service：**

```shell
kubectl expose deployment nginx --port=80 --target-port=80 --name=nginx-server --type=NodePort         #将服务暴露出去

kubectl expose deployment nginx --port=80 --target-port=80 --name=nginx-service --type=NodePort --dry-run -o yaml > nginx-svc.yaml  #生成service配置到yaml文件
```

**删除一个service**
```shell
kubectl delete svc nginx-server
```
**查看service：**

```
[root@MASTER-1 ~]# kubectl get svc
NAME           TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
kubernetes     ClusterIP   10.0.0.1     <none>        443/TCP        3d2h
nginx-server   NodePort    10.0.0.155   <none>        80:33979/TCP   52s
```

**查看pod和svc**

```
[root@MASTER-1 ~]# kubectl get pods,svc
NAME                        READY   STATUS    RESTARTS   AGE
pod/nginx-dbddb74b8-x96v6   1/1     Running   2          25h

NAME                   TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
service/kubernetes     ClusterIP   10.0.0.1     <none>        443/TCP        3d2h
service/nginx-server   NodePort    10.0.0.155   <none>        80:33979/TCP   2m24s
```

**可以使用ipvsadm查看应用分配在哪个节点：**

需要先装ipvsadm工具：`yum  install ipvsadm -y`

**启用ipvsadm要添加如下参数到kube-proxy配置文件**
```shell
--masquerade-all=true
```
**kube-proxy完整配置文件内容如下**：

```
KUBE_PROXY_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=192.168.83.142 \
--cluster-cidr=10.0.0.0/24 \
--proxy-mode=ipvs \
--masquerade-all=true \
--kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig"
```

**ipvsadm -L -n**：查看Pod的负载均衡，通过kube-proxy代理转发

```
[root@NODE-1 ~]# ipvsadm -L -n
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  127.0.0.1:30001 rr
  -> 172.17.90.3:8443             Masq    1      0          0         
TCP  127.0.0.1:33979 rr
  -> 172.17.90.2:80               Masq    1      0          0         
TCP  172.17.90.0:30001 rr
  -> 172.17.90.3:8443             Masq    1      0          0         
TCP  172.17.90.0:33979 rr
  -> 172.17.90.2:80               Masq    1      0          0         
TCP  172.17.90.1:30001 rr
  -> 172.17.90.3:8443             Masq    1      0          0         
TCP  172.17.90.1:33979 rr   	  #可以直接用任意一个node节点的IP加33979端口访问了
  -> 172.17.90.2:80               Masq    1      0          0     #
TCP  192.168.83.142:30001 rr
  -> 172.17.90.3:8443             Masq    1      0          0         
TCP  192.168.83.142:33979 rr
  -> 172.17.90.2:80               Masq    1      0          0         
TCP  10.0.0.1:443 rr
  -> 192.168.83.140:6443          Masq    1      0          0         
  -> 192.168.83.141:6443          Masq    1      1          0         
TCP  10.0.0.50:443 rr
  -> 172.17.90.3:8443             Masq    1      0          0         
TCP  10.0.0.155:80 rr
  -> 172.17.90.2:80               Masq    1      0          0         
```

**查看资源全称与缩写：**
```shell
kubectl api-resources       #列出所有资源的全称和缩写
```

**替换更新镜像**：
```shell
kubectl set image deployment/nginx nginx=nginx1.14

# 更新成功提示如下信息：
[root@MASTER-1 ~]# kubectl set image deployment/nginx nginx=nginx1.14
deployment.extensions/nginx image updated
```
### 升级与回滚：
**升级**：
```shell
kubectl scale rc nginx --replicas=5     #指定资源副本数量

kubectl rolling-update nginx --image=nginx:1.17.0  #版本升级
```
**回滚**：
```shell
kubectl rollout undo  deployment/nginx      #回滚到上一个版本：
```
**查看回滚实时状态**：
```shell
kubectl get pods -w
```
**查看回滚状态信息**：
```shell
[root@k8s-master test]# kubectl rollout status deployment/nginx-deployment
deployment "nginx-deployment" successfully rolled out       #表示成功！
```
**查看所有deployment控制器**
```shell
kubectl get deployment
```
**查看deployment的相关详细信息**：
```shell
kubectl describe deployment/nginx
```
**使用exec进入pod，与docker进入容器的方式是一样的**

```
kubectl exec -it nginx-cdb6b5b95-g2lhz /bin/bash

kubectl get pod coredns-6d8cfdd59d-fbpqs -n kube-system  #查看指定命名空间的Pod
```



