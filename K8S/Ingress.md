# 								Ingress

ingress授权每个应用到达Pod的一个集合；创建一个Ingress需要指定一个service，通过service来获取这组Pod；

#### ingress有三个小结：

##### 1、Pod与Ingress的关系

```
1、通过label-selector相关联
2、通过Ingress Controller实现Pod的负载均衡，-支持TCP/UDP 4层和HTTP 7层
```

2、Ingress Controller
3、Ingress（HTTP与HTTPS）

--------------------------

ingress访问流程：用户---->ingress Controller（在Node上运行的）---->Pod 

Ingress部署文档：https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md

-------------------

### Ingress Controller

#### 创建一个Ingress Controller控制器

下面以Nginx为例，配置文件如下：

vim mandatory.yaml 

```
#创建一个命名空间
apiVersion: v1
kind: Namespace		#资源对象：Namespace
metadata:
  name: ingress-nginx		#创建命名空间的名称；	

---
#configMap，指定ingress-nginx相关的配置文件
kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
#TCP负载均衡（四层）的配置文件，尚未定义
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
#UDP服务负载均衡，尚未定义
kind: ConfigMap
apiVersion: v1
metadata:
  name: udp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
#创建ServiceAccount,因为ingress控制器需要访问apiserver来实时拉取service的相关定义；
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-serviceaccount   #创建ServiceAccount的名称
  namespace: ingress-nginx				#指定分配ServiceAccount到ingress-nginx命名空间
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
#创建一个ClusterRole角色, clusterRole角色类型是基于所有命名空间的
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: nginx-ingress-clusterrole	#创建ClusterRole的名称
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:		#定义授权这个控制器访问Apiserver有哪些权限；
      - configmaps
      - endpoints
      - nodes
      - pods
      - secrets
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - services
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "extensions"
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - "extensions"
    resources:
      - ingresses/status
    verbs:
      - update

---
#创建Role角色，基于命名空间的
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role	#资源对象是Role
metadata:
  name: nginx-ingress-role		#创建Role角色的名称为：nginx-ingress-role
  namespace: ingress-nginx		#分配到ingress-nginx命名空间里面
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:		#定义权限
      - configmaps	#configMap权限
      - pods		#Pod权限
      - secrets		#secret权限
      - namespaces	#namespace权限
    verbs:
      - get			#get查看的权限
  - apiGroups:
      - ""
    resources:
      - configmaps 	#configMap权限
    resourceNames:
      # Defaults to "<election-id>-<ingress-class>"
      # Here: "<ingress-controller-leader>-<nginx>"
      # This has to be adapted if you change either parameter
      # when launching the nginx-ingress-controller.
      - "ingress-controller-leader-nginx"
    verbs:
      - get			#get查看权限
      - update		#update修改权限
  - apiGroups:
      - ""
    resources:
      - configmaps	#configMap权限
    verbs:
      - create		#create创建权限
  - apiGroups:
      - ""
    resources:
      - endpoints	#endpoint权限
    verbs:
      - get			#get是查看的权限

---
#对角色进行绑定，将权限绑定到ServiceAccount
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: nginx-ingress-role-nisa-binding
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-ingress-role
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount	#绑定ServiceAccount的名称
    namespace: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: nginx-ingress-clusterrole-nisa-binding
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-ingress-clusterrole
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---
#创建Deployment控制器，
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  replicas: 1	#部署1个副本
  selector:		#标签选择器
    matchLabels:
      app.kubernetes.io/name: ingress-nginx		#定义的标签：ingress-nginx
      app.kubernetes.io/part-of: ingress-nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      hostNetwork: true		#使用主机网络，因为控制器确保访问的每个Node或者指定的Node都能进入到这个控制器中，因此用户定义的规则才能进行匹配转发到后端的Pod中；
      serviceAccountName: nginx-ingress-serviceaccount	#使用刚授权的ServiceAccount
      containers:		#容器部署
        - name: nginx-ingress-controller
          image: lizhenliang/nginx-ingress-controller:0.20.0	#镜像地址
          args:	#启动的参数如下：
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services	#TCP服务（四层转发）
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services	#UDP服务（四层转发）
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx
            - --annotations-prefix=nginx.ingress.kubernetes.io
          securityContext:		#下面是配置的安全机制
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
            # www-data -> 33
            runAsUser: 33
          env:			#配置变量：
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:	#定义端口，下面容器提供了http端口80、https端口443
            - name: http
              containerPort: 80
            - name: https
              containerPort: 443
          livenessProbe:	#健康检查，对这个控制器的健康检查
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1

---
```

##### 执行创建命令：

kubectl create  -f mandatory.yaml 

```
[root@MASTER-1 ~]# kubectl create -f mandatory.yaml 
namespace/ingress-nginx created
configmap/nginx-configuration created
configmap/tcp-services created
configmap/udp-services created
serviceaccount/nginx-ingress-serviceaccount created
clusterrole.rbac.authorization.k8s.io/nginx-ingress-clusterrole created
role.rbac.authorization.k8s.io/nginx-ingress-role created
rolebinding.rbac.authorization.k8s.io/nginx-ingress-role-nisa-binding created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress-clusterrole-nisa-binding created
deployment.extensions/nginx-ingress-controller created
```

##### 查看刚刚创建的命名空间：

kubectl get ns ingress-nginx

```
[root@MASTER-1 ~]# kubectl get ns ingress-nginx
NAME            STATUS   AGE
ingress-nginx   Active   4m17s
```

##### 查看刚刚创建的Pod:	确保控制器是运行的，因为这个控制器就帮你实现了全局的负载均衡；

kubectl get pods -n ingress-nginx

```
[root@MASTER-1 ~]# kubectl get pods -n ingress-nginx
NAME                                        READY   STATUS    RESTARTS   AGE
nginx-ingress-controller-79888fdc4c-skv26   1/1     Running   0          5m23s
```

##### 查看刚刚创建的Pod分配到哪个节点上：

kubectl get pods -n ingress-nginx -o wide

```
[root@MASTER-1 ~]# kubectl get pods -n ingress-nginx -o wide
NAME                                        READY   STATUS    RESTARTS   AGE     IP               NODE             NOMINATED NODE
nginx-ingress-controller-79888fdc4c-skv26   1/1     Running   0          9m17s   192.168.83.142   192.168.83.142   <none>
```

##### 如上信息可以看到已经分配到了192.168.83.142这个Node上，在142这个Node上会监听两个端口 即是nginx的80和443端口，与宿主机共用一个网络所以Pod中监听的哪些端口都会在宿主机上面呈现，因此创建前需确保宿主机端口未被占用，否则控制器会启动失败！

查看142 Node节点的这两个端口

netstat -tnlp|grep -Ew "80|443"

```
[root@NODE-1 ~]# netstat -tnlp|grep -Ew "80|443"
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      39833/nginx: master 
tcp        0      0 0.0.0.0:443             0.0.0.0:*               LISTEN      39833/nginx: master 
tcp6       0      0 :::80                   :::*                    LISTEN      39833/nginx: master 
tcp6       0      0 :::443                  :::*                    LISTEN      39833/nginx: master
```

如上的80和443端口是Pod的端口

------------------------------------------

### 定义ingress规则：

##### 创建一个ingress： 以http为例；

vim  ingress.yaml

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: simple-fanout-example		#定义ingress名称；
  annotations:		#注解
    nginx.ingress.kubernetes.io/rewrite-target: /  #注解，决定做什么动作
spec:
  rules:	#定义项目通过域名的方式来访问
  - host: foo.bar.com		#设置访问的域名
    http:
      paths:
      - path: /				#访问根目录
        backend:		#定义具体转发到哪个service下的Pod
          serviceName: my-service		#设置service名称：my-service
          servicePort: 80				#设置cluster的端口
```

##### 查看刚刚创建的ingress对象：

kubectl get ingress

```
[root@MASTER-1 ~]# kubectl get ingress
NAME                    HOSTS         ADDRESS   PORTS   AGE
simple-fanout-example   foo.bar.com             80      67s
#名称：				#域名		 #这里为空表示转发到了backend后端，对用户是不可见的由控制器来管理的
```

##### 接下来配置一下host就可以通过域名来访问这个service了；

##### host绑定域名：

Windows系统修改host：

C:\Windows\System32\drivers\etc

打开hosts文件添加如下内容：

192.168.83.142  foo.bar.com

通过ping的方式来测试是否生效即可；

接下来就可以通过浏览器访问了：http://foo.bar.com 

##### 原理：ingress controller通过nginx的proxy负载均衡技术来实现的，涉及到转发就需要配置相关的策略，这些策略就是在ingress-nginx控制器中的；

我们来进入到ingress-nginx控制器来查看相关配置信息：

##### 查看ingress-nginx控制器：

kubectl get pod -n ingress-nginx

```
[root@MASTER-1 ~]# kubectl get pod -n ingress-nginx
NAME                                        READY   STATUS    RESTARTS   AGE
nginx-ingress-controller-79888fdc4c-skv26   1/1     Running   1          46h
```

##### 进入到ingress-nginx控制器中：

kubectl exec -it nginx-ingress-controller-79888fdc4c-skv26 -n ingress-nginx

```
[root@MASTER-1 ~]# kubectl exec -it nginx-ingress-controller-79888fdc4c-skv26 bash -n ingress-nginx
www-data@NODE-1:/etc/nginx$ ls
fastcgi.conf            geoip    mime.types          nginx.conf             scgi_params          uwsgi_params.default
fastcgi.conf.default    koi-utf  mime.types.default  nginx.conf.default     scgi_params.default  win-utf
fastcgi_params          koi-win  modsecurity         opentracing.json       template
fastcgi_params.default  lua      modules             owasp-modsecurity-crs  uwsgi_params
www-data@NODE-1:/etc/nginx$ 
---------------------------------------------------------------------------------------
#由于ingress-nginx控制器使用的是nginx，所以会启动一个nginx来运行的；这个nginx提供了全局的负载均衡；
www-data@NODE-1:/etc/nginx$ ps -ef
UID         PID   PPID  C STIME TTY          TIME CMD
www-data      1      0  0 12:18 ?        00:00:00 /usr/bin/dumb-init /bin/bash /entrypoint.sh /nginx-ingress-controller --configmap=ingress-nginx
www-data      6      1  0 12:18 ?        00:00:00 /bin/bash /entrypoint.sh /nginx-ingress-controller --configmap=ingress-nginx/nginx-configuratio
www-data      7      6  1 12:18 ?        00:00:39 /nginx-ingress-controller --configmap=ingress-nginx/nginx-configuration --tcp-services-configma
www-data     29      7  0 12:18 ?        00:00:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
www-data    138     29  0 12:44 ?        00:00:00 nginx: worker process
www-data    139     29  0 12:44 ?        00:00:00 nginx: worker process
www-data    211      0  0 13:05 pts/0    00:00:00 bash
www-data    217    211  0 13:08 pts/0    00:00:00 ps -ef
---------------------------------------------------------------------------------------
#查看nginx的配置文件：由于配置文件太长了所以这里就过滤了foo.bar.com域名相关的配置信息：
 server {
                server_name foo.bar.com ;

                listen 80;

                listen [::]:80;

                set $proxy_upstream_name "-";

                location / {

                        set $namespace      "default";
                        set $ingress_name   "simple-fanout-example";
                        set $service_name   "my-service";
                        set $service_port   "80";
                        set $location_path  "/";

                        rewrite_by_lua_block {

                                balancer.rewrite()

                        }

                        log_by_lua_block {

                                balancer.log()

                                monitor.call()
                        }

                        port_in_redirect off;

                        set $proxy_upstream_name "default-my-service-80";

                        client_max_body_size                    1m;

                        proxy_set_header Host                   $best_http_host;

                        # Pass the extracted client certificate to the backend

                        # Allow websocket connections
                        proxy_set_header                        Upgrade           $http_upgrade;

                        proxy_set_header                        Connection        $connection_upgrade;

                        proxy_set_header X-Request-ID           $req_id;
                        proxy_set_header X-Real-IP              $the_real_ip;

                        proxy_set_header X-Forwarded-For        $the_real_ip;

                        proxy_set_header X-Forwarded-Host       $best_http_host;
                        proxy_set_header X-Forwarded-Port       $pass_port;
                        proxy_set_header X-Forwarded-Proto      $pass_access_scheme;

                        proxy_set_header X-Original-URI         $request_uri;

                        proxy_set_header X-Scheme               $pass_access_scheme;

                        # Pass the original X-Forwarded-For
                        proxy_set_header X-Original-Forwarded-For $http_x_forwarded_for;

                        # mitigate HTTPoxy Vulnerability
                        # https://www.nginx.com/blog/mitigating-the-httpoxy-vulnerability-with-nginx/
                        proxy_set_header Proxy                  "";

                        # Custom headers to proxied server

                        proxy_connect_timeout                   5s;
                        proxy_send_timeout                      60s;
                        proxy_read_timeout                      60s;

                        proxy_buffering                         off;
                        proxy_buffer_size                       4k;
                        proxy_buffers                           4 4k;
                        proxy_request_buffering                 on;

                        proxy_http_version                      1.1;

                        proxy_cookie_domain                     off;
                        proxy_cookie_path                       off;

                        # In case of errors try the next upstream server before returning an error
                        proxy_next_upstream                     error timeout;
                        proxy_next_upstream_tries               3;

                        proxy_pass http://upstream_balancer;

                        proxy_redirect                          off;

                }

        }
```

以上是http配置的



### 创建一个ingress：以https为例；

##### 首先签发证书：

脚本内容如下：

vim  certs.sh

```
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

cat > sslexample.foo.com-csr.json <<EOF
{
  "CN": "sslexample.foo.com",
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

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes sslexample.foo.com-csr.json | cfssljson -bare sslexample.foo.com 
```

##### 脚本注解如下：

```
cat > ca-config.json <<EOF						#自签一个CA
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF					#CA的请求
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca -



cat > sslexample.foo.com-csr.json <<EOF			#配置文件名称
{
  "CN": "sslexample.foo.com",		#配置访问的域名；
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

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes sslexample.foo.com-csr.json | cfssljson -bare sslexample.foo.com   # sslexample.foo.com是生成证书的前缀；

下面这条命令是将生成的证书导入到secret存储
#kubectl create secret tls blog-ctnrs-com --cert=blog.ctnrs.com.pem --key=blog.ctnrs.com-key.pem

```

##### 执行cert.sh脚本：

sh  certs.sh

```
[root@MASTER-1 ~]# sh certs.sh 
2019/12/10 21:49:18 [INFO] generating a new CA key and certificate from CSR
2019/12/10 21:49:18 [INFO] generate received request
2019/12/10 21:49:18 [INFO] received CSR
2019/12/10 21:49:18 [INFO] generating key: rsa-2048
2019/12/10 21:49:19 [INFO] encoded CSR
2019/12/10 21:49:19 [INFO] signed certificate with serial number 261846208410852180566493177884448295208864223464
2019/12/10 21:49:19 [INFO] generate received request
2019/12/10 21:49:19 [INFO] received CSR
2019/12/10 21:49:19 [INFO] generating key: rsa-2048
2019/12/10 21:49:19 [INFO] encoded CSR
2019/12/10 21:49:19 [INFO] signed certificate with serial number 2207130298831853641304582487794104804149751939
2019/12/10 21:49:19 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
#看到如上信息表示成功！
```

证书生成之后会有两个文件：sslexample.foo.com.pem和sslexample.foo.com-key.pem，需要用到这两个文件

```
[root@MASTER-1 demo2]#  ll
-rw-r--r-- 1 root root  294 12月 10 21:53 ca-config.json
-rw-r--r-- 1 root root  960 12月 10 21:53 ca.csr
-rw-r--r-- 1 root root  212 12月 10 21:53 ca-csr.json
-rw------- 1 root root 1679 12月 10 21:53 ca-key.pem
-rw-r--r-- 1 root root 1273 12月 10 21:53 ca.pem
-rw-r--r-- 1 root root 1113 12月 10 21:49 certs.sh					#刚刚执行的脚本文件
-rw-r--r-- 1 root root  968 12月 10 21:53 sslexample.foo.com.csr
-rw-r--r-- 1 root root  191 12月 10 21:53 sslexample.foo.com-csr.json
-rw------- 1 root root 1679 12月 10 21:53 sslexample.foo.com-key.pem	#证书key文件
-rw-r--r-- 1 root root 1318 12月 10 21:53 sslexample.foo.com.pem		#证书文件
```

##### 通过kubectl将证书保存到secret里面：

```
kubectl create secret tls sslexample.foo.com --cert=sslexample.foo.com.pem --key=sslexample.foo.com-key.pem
```

注意：上面一定要指定tls类型

##### 命令参数详解：

tls：类型

sslexample.foo.com：证书的名称

--cert=sslexample.foo.com.pem：指定证书文件

--key=sslexample.foo.com-key.pem：指定证书key文件

##### 查看刚刚导入的secret

kubectl get secret sslexample.foo.com

```
[root@MASTER-1 demo2]# kubectl get secret sslexample.foo.com
NAME                 TYPE                DATA   AGE
sslexample.foo.com   kubernetes.io/tls   2      3m36s
```

##### 接下来创建一个ingress：

官方案例：https://v1-16.docs.kubernetes.io/zh/docs/concepts/services-networking/ingress/

vim  ingress-https.yaml

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: tls-example-ingress
spec:
  tls:
  - hosts:
    - sslexample.foo.com
    secretName: sslexample.foo.com	  #这里要指定上面创建的secret名称为：sslexample.foo.com
  rules:
    - host: sslexample.foo.com				#指定域名
      http:
        paths:
        - path: /							#表示/根目录
          backend:
            serviceName: my-service			#指定service
            servicePort: 80					#service 的端口
```

#### 执行创建ingress

 kubectl apply -f ingress-https.yaml 

接下来绑定hosts就可以通过https来访问sslexample.foo.com了

--------------------------------

### 小结：

ingress提供了一下几个功能：

1、四层、七层复杂均衡转发

2、支持自定义service访问策略

3、只支持基于域名的网站访问

4、支持TLS 

访问流程：

用户——>域名——>负载均衡器——>ingress controller（Node）——>Pod





































