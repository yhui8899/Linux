# k8s常用命令

### Master主节点相关操作

```
更改配置文件，重新加载
systemctl daemon-reload
启动master相关组件
systemctl start kube-apiserver/kube-controller-manager/ube-scheduler/etcd.service
停止master相关组件
systemctl stop kube-apiserver/kube-controller-manager/ube-scheduler/etcd.service
重启master相关组件
systemctl restart kube-apiserver/kube-controller-manager/ube-scheduler/etcd.service
查看master相关组件状态
systemctl status kube-apiserver/kube-controller-manager/ube-scheduler/etcd.service
查看各组件信息
kubectl get componentstatuses
查看kubelet进程启动参数
ps -ef | grep kubelet
查看日志:
journalctl -u kubelet -f
查看集群信息
kubectl cluster-info
查看各组件信息
kubectl -s http://localhost:8080 get componentstatuses
```

### NODE工作节点相关操作

```
启动worker端相关组件
systemctl start kube-proxy/docker/kubelet
停止worker端相关组件
systemctl stop kube-proxy/docker/kubelet
重启worker端相关组件
systemctl restart kube-proxy/docker/kubelet
查看worker端相关组件状态
systemctl status kube-proxy/docker/kubelet
```

### 节点相关操作

```javascript
设为node为不可调度状态：
kubectl cordon node1
解除node不可调度状态
kubectl uncordon node1
将pod赶到其他节点：
kubectl drain node1
master运行pod
kubectl taint nodes master.k8s node-role.kubernetes.io/master-
master不运行pod
kubectl taint nodes master.k8s node-role.kubernetes.io/master=:NoSchedule
```

### 查看类命令

```javascript
获取节点相应服务的信息：
kubectl get nodes
查看pod相关信息
kubectl get pods
查看指定namespace的pod信息
kubectl get pods -n namespace
按selector名来查找pod
kubectl get pod --selector name=redis
查看集群所有的pod信息
kubectl get pods -A
查看pods所在的运行节点
kubectl get pods -o wide
查看pods定义的详细信息
kubectl get pods -o yaml
查看运行的pod的环境变量
kubectl exec pod名 env
查看指定pod的日志
kubectl logs  podname
滚动查看指定pod的日志
kubectl logs -f podname
查看service相关信息
kubectl get services
查看deployment相关信息
kubectl get deployment
查看指定pod的详细信息
kubectl describe pods-dasdeqwew2312-g6q8c
查看deployment历史修订版本
kubectl rollout history deployment/nginx-deployment
```

### 操作类命令

```javascript
创建资源
kubectl create -f xx.yaml
重建资源
kubectl replace -f xx.yaml  [--force]
删除资源
kubectl delete -f xx.yaml
删除指定pod
kubectl delete pod podname
删除指定rc
kubectl delete rc rcname
删除指定service
kubectl delete service servicename
删除所有pod
kubectl delete pod --all
导出所有configmap
kubectl get configmap -n kube-system -o wide -o yaml > configmap.yaml
进入pod
kubectl exec -it redis-master-1033017107-q47hh /bin/sh
增加lable值
kubectl label pod redis-master-1033017107-q47hh role=master 
修改lable值
kubectl label pod redis-master-1033017107-q47hh role=backend --overwrite
更新资源
kubectl patch pod rc-nginx-2-kpiqt -p '{"metadata":{"labels":{"app":"nginx-3"}}}'
```

### 升级相关

```javascript
指定资源副本数量（扩容缩容）
kubectl scale rc nginx --replicas=5
版本升级
kubectl rolling-update redis-master --image=redis-master:2.0
版本回滚
kubectl rolling-update redis-master --image=redis-master:1.0 --rollback
实时观察滚动升级状态
kubectl rollout status deployment/nginx-deployment
```

