# 							RBAC安全机制-权限分配

### RBAC安全机制介绍：

```shell
1.  Kubernetes的安全框架

2.  传输安全，认证，授权，准入控制

3.  使用RBAC授权
```

#### 一、Kubernetes的安全框架

```shell
1）、访问K8S集群的资源需要过三关：认证、鉴权、准入控制

2）、普通用户若要安全访问集群API Server，往往需要证书、Token或者用户名+密码；Pod访问，需要ServiceAccount

3）、K8S安全控制框架主要由下面3个阶段进行控制，每一个阶段都支持插件方式，通过API Server配置来启用插件。

#三层认证
1、Authentication		#传输、认证环节
2、Authorization			#授权环节
3、Admission Control		#准入控制
```

#### 二、传输安全，认证

**传输安全**：

- 告别8080，迎接6443

**认证**

- 三种客户端身份认证：

```shell
HTTPS 证书认证：基于CA证书签名的数字证书认证

HTTP Token认证：通过一个Token来识别用户

HTTP Base认证：用户名+密码的方式认证
```

#### 三、授权：

RBAC（Role-Based Access Control，基于角色的访问控制）：负责完成授权（Authorization）工作。

- 角色：	定义用户是否有权限访问资源

```shell
Role：授权特定命名空间的访问权限，	

ClusterRole：授权所有命名空间的访问权限
```

- 角色绑定：	角色与某个用户或对象绑定，

	RoleBinding：将角色绑定到主体（即subject），根据上面的角色绑定即可，如RoleBinding对应的角色是Role
		
	ClusterRoleBinding：将集群角色绑定到主体，根据上面的角色绑定即可，如ClusterRoleBinding对应的角色是ClusterRole

- 主体（subject）

```shell
User：用户

Group：用户组

ServiceAccount：服务账号，服务账号是给程序使用的
```

#### 四、准入控制

**AdminssionControl**实际上是一个准入控制器插件列表，发送到APIServer的请求都需要经过这个列表中的每个准入控制器插件的检查，检查不通过，则拒绝请求。

```shell
1.11版本以上推荐使用的插件：
--enable-admission-plugins= \
NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds, ResourceQuota  #此配置在kube-apiserver配置文件中配置
```

----------------------------------

### 使用RBAC授权

- 角色授权与绑定：

### 示例：

**目的：**

- user测试：创建一个命名空间来测试，创建角色并分配权限然后RoleBinding来绑定角色，颁发一个客户端用户证书来测试。
- ServiceAccount测试：根据创建的角色权限然后创建一个ServiceAccount来绑定刚才创建的角色，让UI也可以访问;

##### 示例1：

**1、先创建一个namespace来做测试**：

```shell
kubectl  create  ns  ctnrs
```

**2、创建几个Pod服务来做测试**：

```shell
kubectl run nginx --image=nginx -n ctnrs				# -n  创建到指定的命名空间下
```

- pod扩容：

  kubectl scale deploy/nginx --replicas=3 -n ctnrs		# --replicas=3	扩容的数量；  -n  指定命名空间

```
[root@MASTER-1 demo]# kubectl scale deploy/nginx --replicas=3 -n ctnrs
deployment.extensions/nginx scaled
[root@MASTER-1 demo]# kubectl get pods -n ctnrs
NAME                    READY   STATUS    RESTARTS   AGE
nginx-dbddb74b8-459sb   1/1     Running   0          4m48s
nginx-dbddb74b8-6jhrn   1/1     Running   0          70s
nginx-dbddb74b8-hstlx   1/1     Running   0          70s
```

- 查看刚刚创建的pod

```shell
kubectl get pods -n ctnrs
```

**3、创建角色：授权对Pod读取权限：**

​	vim  rbac-role.yaml 

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ctnrs			#授权访问的命名空间
  name: pod-reader			#创建的角色名称	
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]				# 权限：只能操作pods资源；
  verbs: ["get", "watch", "list"]	#给角色权限分配：get、watch、list 分配了这三个只读权限；
```

- 执行创建命令：

```shell
kubectl apply -f rbac-role.yaml 
```

- 查看刚刚创建的角色：

  kubectl get -n ctnrs role				#要指定命名空间才能看到角色；

```
[root@MASTER-1 demo]# kubectl get -n ctnrs role
NAME         AGE
pod-reader   64s
```

**4、创建一个RoleBinding来绑定角色**

​	vim   rbac-role.yaml

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: ctnrs
subjects:			#绑定主体：即用户、用户组或服务账号；
- kind: User		#指定的是用户，如果指定的是程序就是：ServiceAccount
  name: xiaofeige	# 用户 
  apiGroup: rbac.authorization.k8s.io	#API组
roleRef:			#绑定角色
  kind: Role 		#对象是角色
  name: pod-reader	#绑定的角色名称，就是刚刚创建的pod-reader
  apiGroup: rbac.authorization.k8s.io    #API组
```

- 执行创建命令：

```shell
kubectl apply -f rbac-role.yaml
```

- 查看刚刚创建的角色和绑定信息：

  kubectl get -n ctnrs role,rolebinding

```
[root@MASTER-1 demo]# kubectl get -n ctnrs role,rolebinding
NAME                                        AGE
role.rbac.authorization.k8s.io/pod-reader   35s			#role 角色

NAME                                              AGE
rolebinding.rbac.authorization.k8s.io/read-pods   9m20s  # rolebinding，绑定角色
```

如上所示已经将用户和角色绑定到一块了；

**5、识别身份：**

##### 颁发一个客户端证书，创建一个目录：mkdir  xiaofeige    将创建证书的脚本放至目录中,脚本内容如下：

vim rabc-user.sh

```
cat > xiaofeige-csr.json <<EOF
{
  "CN": "xiaofeige",			#这里填写识别的用户
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "ST": "BeiJing"
    }
  ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes xiaofeige-csr.json | cfssljson -bare xiaofeige

kubectl config set-cluster kubernetes \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://192.168.83.141:6443 \
  --kubeconfig=xiaofeige-kubeconfig

kubectl config set-credentials xiaofeige \
  --client-key=xiaofeige-key.pem \
  --client-certificate=xiaofeige.pem \
  --embed-certs=true \
  --kubeconfig=xiaofeige-kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=xiaofeige \
  --kubeconfig=xiaofeige-kubeconfig

kubectl config use-context default --kubeconfig=xiaofeige-kubeconfig
```

- rabc-user.sh脚本注解如下：

```
cat > aliang-csr.json <<EOF
{
  "CN": "xiaofeige",				#这里填写识别的用户名
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "ST": "BeiJing"
    }
  ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes aliang-csr.json | cfssljson -bare xiaofeige 
#注意：生成证书时需要指定根证书，就是在生成APIserver时的SSL证书目录位置，会用到：-ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json 文件

kubectl config set-cluster kubernetes \		#设置集群，连接集群的IP
  --certificate-authority=ca.pem \			#集群的CA证书
  --embed-certs=true \			#此选项是将ca.pem证书写到下面的：xiaofeige-kubeconfig文件里
  --server=https://192.168.83.141:6443 \	#如果是高可用的话直接设置VIP即可
  --kubeconfig=xiaofeige-kubeconfig			#生成配置文件
  
kubectl config set-credentials xiaofeige \	#配置客户端证书
  --client-key=xiaofeige-key.pem \			#客户端key
  --client-certificate=xiaofeige.pem \		#客户端证书
  --embed-certs=true \						#写到xiaofeige-kubeconfig配置文件中
  --kubeconfig=xiaofeige-kubeconfig			#配置文件名称

kubectl config set-context default \ #设置上下文，一个配置中可有多个连接集群，只要指定默认上下文即可
  --cluster=kubernetes \		#使用的是kubernetes集群；
  --user=xiaofeige \			#用户是：xiaofeige
  --kubeconfig=xiaofeige-kubeconfig

kubectl config use-context default --kubeconfig=xiaofeige-kubeconfig	#设置默认上下文

```

- 将需要用到的证书文件拷贝到当前目录(xiaofeige)，以前创建apiserver的ssl证书目录

  cp /root/k8s/k8s-cert/ca* .

```
[root@MASTER-1 xiaofeige]# ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem  rbac-user.sh
#生成证书第一步使用apiserver生成的证书去生成
#第二，生成kube配置文件连接集群信息和证书信息
```

- 执行脚本：

  sh rbac-user.sh  

报错：

```
Use "kubectl options" for a list of global command-line options (applies to all commands).
error: Unexpected args: [default  ]
rbac-user.sh:行35: --cluster=kubernetes: 未找到命令
rbac-user.sh:行36: --user=xiaofeige: 未找到命令
rbac-user.sh:行37: --kubeconfig=xiaofeige-kubeconfig: 未找到命令
error: no context exists with the name: "default".

解决方法：
这个问题可能是Windows下格式的问题，
使用如下命令格式化一下即可：
dos2unix rbac-user.sh
提示:
[root@MASTER-1 xiaofeige]# dos2unix rbac-user.sh 
dos2unix: converting file rbac-user.sh to Unix format ...
如果没有dos2unix命令需要安装一下“
yum install dos2unix -y
在执行脚本即可；
```

```
sh rbac-user.sh  
[root@MASTER-1 xiaofeige]# sh rbac-user.sh       
2019/12/03 22:44:58 [INFO] generate received request
2019/12/03 22:44:58 [INFO] received CSR
2019/12/03 22:44:58 [INFO] generating key: rsa-2048
2019/12/03 22:44:58 [INFO] encoded CSR
2019/12/03 22:44:58 [INFO] signed certificate with serial number 237720153155367234971690736609064064418087072008
2019/12/03 22:44:58 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
Cluster "kubernetes" set.
User "xiaofeige" set.
Context "default" created.
Switched to context "default".
看到此信息表示成功；
```

- 执行脚本后会生成如下文件：

```
ca-config.json  #原来生成apiserver的文件
ca-csr.json  	#原来生成apiserver的文件
ca.pem   		#原来生成apiserver的文件
ca.csr			#原来生成apiserver的文件
ca-key.pem 		#原来生成apiserver的文件
xiaofeige.csr   #新生成的配置文件   
xiaofeige-key.pem      #新生成的配置文件 
xiaofeige.pem			 #新生成的配置文件 
xiaofeige-csr.json		 #新生成的配置文件   	
xiaofeige-kubeconfig	 #新生成的配置文件，此文件里面存放着证书秘钥
rbac-user.sh 	#脚本文件
```

- 测试一下：

  kubectl --kubeconfig=xiaofeige-kubeconfig get pods -n ctnrs

```
[root@MASTER-1 xiaofeige]# kubectl --kubeconfig=xiaofeige-kubeconfig get pods -n ctnrs
NAME                    READY   STATUS    RESTARTS   AGE
nginx-dbddb74b8-459sb   1/1     Running   0          107m
nginx-dbddb74b8-6jhrn   1/1     Running   0          103m
nginx-dbddb74b8-hstlx   1/1     Running   0          103m
```

如上信息可以看到已经查看到ctnrs命名空间的pod了，表示成功！

- 再试试查看svc资源：

  kubectl --kubeconfig=xiaofeige-kubeconfig get svc -n ctnrs

```
[root@MASTER-1 xiaofeige]# kubectl --kubeconfig=xiaofeige-kubeconfig get svc -n ctnrs    
Error from server (Forbidden): services is forbidden: User "xiaofeige" cannot list resource "services" in API group "" in the namespace "ctnrs"
```

报错了，因为我们给的权限是查看pod的，所以查看不了svc；提示：cannot list resource "services" ，不能列出services资源；

**6、创建一个ServiceAccount来绑定刚才创建的角色，让UI也可以访问**;

vim  sa.yaml

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-reader
  namespace: ctnrs

---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-pods
  namespace: ctnrs
subjects:
- kind: ServiceAccount
  name: pod-reader
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

- 注解如下：

```
apiVersion: v1
kind: ServiceAccount			#资源对象是：ServiceAccount
metadata:
  name: pod-reader				#ServiceAccount的名称
  namespace: ctnrs				#指定命名空间：ctnrs

---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-pods
  namespace: ctnrs
subjects:
- kind: ServiceAccount		#指定程序访问：ServiceAccount，如果是用户访问即：User
  name: pod-reader			#指定的是上面ServiceAccount的名字	
roleRef:
  kind: Role
  name: pod-reader			#访问的权限角色名称，这里使用的是刚才只读pod的权限
  apiGroup: rbac.authorization.k8s.io
```

- 执行创建命令：

```shell
kubectl apply -f sa.yaml
```

- 查看刚刚创建的ServiceAccount

kubectl get sa -n ctnrs 

```
[root@MASTER-1 xiaofeige]# kubectl get sa -n ctnrs  
NAME         SECRETS   AGE
default      1         140m
pod-reader   1         89s
```

- 查看pod-reader的token，因为我们要用这个token来登录UI

kubectl describe secret -n ctnrs pod-reader 

```
[root@MASTER-1 xiaofeige]# kubectl describe secret -n ctnrs pod-reader   
Name:         pod-reader-token-tc95r
Namespace:    ctnrs
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: pod-reader
              kubernetes.io/service-account.uid: a377de0b-15e0-11ea-adc5-000c29100356

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1359 bytes
namespace:  5 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJjdG5ycyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJwb2QtcmVhZGVyLXRva2VuLXRjOTVyIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6InBvZC1yZWFkZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJhMzc3ZGUwYi0xNWUwLTExZWEtYWRjNS0wMDBjMjkxMDAzNTYiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6Y3RucnM6cG9kLXJlYWRlciJ9.SF1znqmrDDx0xrRnieUjEP-0vclPTMssMkKaKEMfqNkaaRrnNvBdFRzxyILv0FcjIgm7hvmao0zYrnk9PWHLMxbMWK1a2OMRo3JUGx8xP1tD375164nb_r4hwJ2KTJHV8PlBjlnJ_1VWu9WeT6UPNOoyzYsG6M02TXvQN_ppMFCI4Mn5r7N0Ky8z65SG0dFQYZYJSmkbclloZc7iV6GgsofGMsyviuYCRqK20eNWcofiEBvOi8IXg1lj4jgzMFzKBuw-4ceKLqxyAlC-Kyymsp8Q619eMFdjHlJzJ5Jt7M_0TThgtvQbkBc8RjqzEVTSHNcgBO5z7glotApRUtFIzg
```

获取到token之后，接下来我们就可以拿着token去登录UI了；

这就是使用RBAC授权，可以让一个用户或ServiceAccount访问某些权限，RBAC在实际应用环境中一般都要启用的也是k8s安全机制非常的关键点，用于实现用户访问授权的资源做细化权限的控制，提高架构的安全性；