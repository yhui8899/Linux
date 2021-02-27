# deployment控制器

deployment控制器适用于无状态应用：

以nginx为例：

vim nginx-deployment.yaml

```shell
apiVersion: apps/v1	  #资源对象版本，apps/v1为稳定版
kind: Deployment		#资源对象控制器；
metadata:				#元数据信息
  name: nginx-deployment		#创建deployment的名称
  labels:						#标签
    app: nginx					#定义一个标签
spec:
  replicas: 3		 	#副本数，就是创建pod实例数量
  selector:				#标签选择器
    matchLabels:		#匹配标签
      app: nginx		#关联上面元数据信息的标签
  template:					#被管理对象，也就是容器
    metadata:				#容器的元数据
      labels:				#容器的标签
        app: nginx			#定义pod容器标签，一般保持和上面元数据的标签一致即可！
    spec:
      containers:					#容器定义
      - name: nginx					#容器名称
        image: nginx:1.15.4			#容器的镜像及版本
        ports:
        - containerPort: 80			#容器内部端口
```

执行创建一个deployment

```SHELL
kubectl create -f nginx-deployment.yaml
#查看刚刚创建的deployment
[root@k8s-master test]# kubectl get deployment/nginx-deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           39m
```

使用kubectl create 和kubectl apply的区别：
```shell
kubectl create -f nginx.yaml  #只创建资源不做更新。
kubectl apply -f  nginx.yaml  #申明式更新资源，apiserver只会更新yaml文件中更新的字段，不会重建资源除非更换了镜像，如果资源不存在则会先创建资源，注意如果不支持申明式更新的字段会抛出一堆错误；
```

------------------------

**k8s拉取私有仓库镜像**

以Tomcat为例拉取私有仓库镜像：拉取私有仓库的镜像需要先获取到token然后创建secret

首先在一台Node节点上登录harbor仓库：

```shell
[root@k8s-node1 ~]# docker login 192.168.2.110
Username: admin
Password:
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded

#登录后会生成一个token信息，需要拿着token凭据去请求harbor私有仓库：
[root@k8s-node1 ~]# cat .docker/config.json
{
        "auths": {
                "192.168.2.110": {
                        "auth": "YWRtaW46YXZzY2hpbmExcWEyd3M="
                }
        },
        "HttpHeaders": {
                "User-Agent": "Docker-Client/18.09.6 (linux)"
        }
#需要将转换为base64
[root@k8s-node1 ~]# cat .docker/config.json |base64 -w 0		#转换为base64编码，-w 0 参数表示不换行
ewoJImF1dGhzIjogewoJCSIxOTIuMTY4LjIuMTEwIjogewoJCQkiYXV0aCI6ICJZV1J0YVc0NllYWnpZMmhwYm1FeGNXRXlkM009IgoJCX0KCX0sCgkiSHR0cEhlYWRlcnMiOiB7CgkJIlVzZXItQWdlbnQiOiAiRG9ja2VyLUNsaWVudC8xOC4wOS42IChsaW51eCkiCgl9Cn0=
```

创建一个secret来管理harbor的凭据：

vim registry-pull-secret.yaml

```shell
apiVersion: v1		#secret的api版本
kind: Secret		#资源对象是secret
metadata: 			#元数据信息
  name: registry-pull-secret		#定义这个secret资源的名称，需要使用这个名称来作为拉取镜像策略
data: 					
  .dockerconfigjson: 	ewoJImF1dGhzIjogewoJCSIxOTIuMTY4LjIuMTEwIjogewoJCQkiYXV0aCI6ICJZV1J0YVc0NllYWnpZMmhwYm1FeGNXRXlkM009IgoJCX0KCX0sCgkiSHR0cEhlYWRlcnMiOiB7CgkJIlVzZXItQWdlbnQiOiAiRG9ja2VyLUNsaWVudC8xOC4wOS42IChsaW51eCkiCgl9Cn0=	#保存的touke数据
type: kubernetes.io/dockerconfigjson
```

执行创建secret：

```sehll
kubectl create -f registry-pull-secret.yaml

[root@k8s-master test]# kubectl get secret|grep registry-pull-secret
registry-pull-secret                 kubernetes.io/dockerconfigjson     1    3m52s  #数据显示是1表示正常如果显示是0的话说明数据没保存进去
```

创建tomcat-deployment

vim tomcat-deployment.yaml

```shell
apiVersion: apps/v1	  #资源对象版本，apps/v1为稳定版
kind: Deployment		#资源对象控制器；
metadata:				#元数据信息
  name: tomcat-deployment		#创建deployment的名称
  labels:						#标签
    app: tomcat					#定义一个标签
spec:
  replicas: 3		 	#副本数，就是创建pod实例数量
  selector:				#标签选择器
    matchLabels:		#匹配标签
      app: tomcat		#关联上面元数据信息的标签
  template:					#被管理对象，也就是容器
    metadata:				#容器的元数据
      labels:				#容器的标签
        app: tomcat			#定义pod容器标签，一般保持和上面元数据的标签一致即可！
    spec:
      imagePullSecrets: 						#镜像拉取的凭据，与container是平级的，针对所有容器拉取
      -name: registry-pull-secret				#这个是secret的名称，使用这个secret作为凭据来拉取镜像
      containers:								#容器定义
      - name: tomcat							#容器名称
        image: 192.168.2.110/gqsx/tomcat:latest			#容器的镜像及版本
        imagePullPolicy: Always							#Always：每次都会拉取镜像
        ports:
        - containerPort: 8080					#容器内部端口
   
---
apiVersion: v1		#指定资源对象api的版本	
kind: Service		#指定资源对象
metadata:			#元数据信息
  name: tomcat-service	#设置service的名称
  labels: 				#标签
    app: tomcat			#通过这个标签关联后端的哪些Pod，要与tomcat-deployment控制器的一致,匹配的是pod的标签
spec:
  type: NodePort		#指定service的类型，这里为NodePort
  ports: 
  - port: 80				#对外暴露服务的端口
    targetPort: 8080		#目的端口也就是容器端口
  selector:				#标签选择器
    app: tomcat			#匹配tomcat的标签，与上面的元数据标签一致即可！
```



