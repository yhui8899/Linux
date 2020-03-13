# Kubernetes部署：

### IP地址规划如下：

MASTER节点-1：192.168.83.141

MASTER节点-2：192.168.83.140

NODE节点1：192.168.83.142

NODE节点2:	192.168.83.143

LB负载均衡1：192.168.83.135	nginx+keepalived

LB负载均衡2：192.168.83.136	nginx+keepalived

VIP：192.168.83.254



到github下载安装包：

https://github.com/kubernetes/kubernetes/releases

或者到网盘下载：

链接：https://pan.baidu.com/s/1qngptPQuqYtaK21F6MhUFw 密码：ba2c

如要准备的软件包如下：

kubernetes-server-linux-amd64.tar.gz

etcd-v3.3.10-linux-amd64.tar.gz

flannel-v0.10.0-linux-amd64.tar.gz



##### 创建K8S工作目录，将相关安装包放至该目录

mkdir  k8s

cd k8s



### 自签ssl证书：

采用cfssl签发证书：

脚本1、：cfssl.sh

脚本2：etcd-cert.sh

安装cfssl证书签发工具脚本内容如下：

cfssl.sh 内容如下：

```
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o /usr/local/bin/cfssl-certinfo
chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson /usr/local/bin/cfssl-certinfo
```

以上脚本内容其实就是将二进制文件下载下来放至 /usr/local/bin/目录下，然后给予执行权限即可；

创建etcd-cert目录：

mkdir etcd-cert

将etcd-cert.sh脚本移动到etcd-cert目录下：

mv etcd-cert.sh   etcd-cert/

etcd-cert.sh  脚本内容如下：

```
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "www": {
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
    "CN": "etcd CA",
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

# -----------------------

cat > server-csr.json <<EOF
{
    "CN": "etcd",
    "hosts": [
    "192.168.83.141",
    "192.168.83.142",
    "192.168.83.143"
    ],
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

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server
```

#### 生成证书步骤：

##### 1、在etcd-cert目录下执行如下代码，会自动生成ca-config.json文件

```
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "www": {
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
```

##### 2、执行如下代码，会自动生成ca-csr.json文件

```
cat > ca-csr.json <<EOF
{
    "CN": "etcd CA",
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
```

##### 3、执行如下命令生成证书：自动生成：ca-key.pem、ca.pem、ca.csr  三个文件

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
执行成功出现如下提示：
2019/11/05 21:16:03 [INFO] generating a new CA key and certificate from CSR
2019/11/05 21:16:03 [INFO] generate received request
2019/11/05 21:16:03 [INFO] received CSR
2019/11/05 21:16:03 [INFO] generating key: rsa-2048
2019/11/05 21:16:03 [INFO] encoded CSR
2019/11/05 21:16:03 [INFO] signed certificate with serial number 202716895405456479329034607509292675362751624156
```

##### 4、执行如下代码生成server-csr.json文件：

```
cat > server-csr.json <<EOF
{
    "CN": "etcd",
    "hosts": [
    "192.168.83.141",	
    "192.168.83.142",
    "192.168.83.143"
    ],
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
```

##### 5、执行如下命令生成证书：

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server
```

##### 成功生成提示如下：

```
[root@MASTER-1 etcd-cert]# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server
2019/11/05 21:47:11 [INFO] generate received request
2019/11/05 21:47:11 [INFO] received CSR
2019/11/05 21:47:11 [INFO] generating key: rsa-2048
2019/11/05 21:47:11 [INFO] encoded CSR
2019/11/05 21:47:11 [INFO] signed certificate with serial number 230788602063752652498870933783526473884670517765
2019/11/05 21:47:11 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").

上面一个警告可以忽略
```

最后生成：server.pem、server-key.pem 两个证书文件表示成功；



## Etcd数据库集群部署

etcd节点IP地址：

节点1：192.168.83.141

节点2：192.168.83.142

节点3：192.168.83.143

**三台etcd服务器都必须效验时间，因时间不一致可能会报错**

ntpdate time.windows.com

**创建etcd安装目录：**

mkdir -p /opt/etcd/{cfg,bin,ssl}

解压etcd-v3.3.10-linux-amd64.tar.gz文件

tar -xf  etcd-v3.3.10-linux-amd64.tar.gz

将etcd、etcdctl两个二进制文件拷贝到/opt/etcd/bin/目录下

mv etcd-v3.3.10-linux-amd64/etcd etcd-v3.3.10-linux-amd64/etcdctl  /opt/etcd/bin/

将ssl证书文件拷贝到/opt/etcd/ssl目录下

cp etcd-cert/*.pem /opt/etcd/ssl/

etcd脚本文件内容如下：etcd.sh

```
# !/bin/bash

# example: ./etcd.sh etcd01 192.168.1.10 etcd02=https://192.168.1.11:2380,etcd03=https://192.168.1.12:2380

ETCD_NAME=$1
ETCD_IP=$2
ETCD_CLUSTER=$3

WORK_DIR=/opt/etcd

cat <<EOF >$WORK_DIR/cfg/etcd

# [Member]

ETCD_NAME="${ETCD_NAME}"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://${ETCD_IP}:2380"
ETCD_LISTEN_CLIENT_URLS="https://${ETCD_IP}:2379"

# [Clustering]

ETCD_INITIAL_ADVERTISE_PEER_URLS="https://${ETCD_IP}:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://${ETCD_IP}:2379"
ETCD_INITIAL_CLUSTER="etcd01=https://${ETCD_IP}:2380,${ETCD_CLUSTER}"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

cat <<EOF >/usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=${WORK_DIR}/cfg/etcd
ExecStart=${WORK_DIR}/bin/etcd \
--name=\${ETCD_NAME} \
--data-dir=\${ETCD_DATA_DIR} \
--listen-peer-urls=\${ETCD_LISTEN_PEER_URLS} \
--listen-client-urls=\${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \
--advertise-client-urls=\${ETCD_ADVERTISE_CLIENT_URLS} \
--initial-advertise-peer-urls=\${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
--initial-cluster=\${ETCD_INITIAL_CLUSTER} \
--initial-cluster-token=\${ETCD_INITIAL_CLUSTER_TOKEN} \
--initial-cluster-state=new \
--cert-file=${WORK_DIR}/ssl/server.pem \
--key-file=${WORK_DIR}/ssl/server-key.pem \
--peer-cert-file=${WORK_DIR}/ssl/server.pem \
--peer-key-file=${WORK_DIR}/ssl/server-key.pem \
--trusted-ca-file=${WORK_DIR}/ssl/ca.pem \
--peer-trusted-ca-file=${WORK_DIR}/ssl/ca.pem
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etcd
systemctl restart etcd
```

执行脚本命令：

sh etcd.sh etcd01 192.168.83.141 etcd02=https://192.168.83.142:2380,etcd03=https://192.168.83.143:2380

执行之后会等待其他两台机器接入

在这个时候比较容易出问题的是证书，可以用cfssl-certinfo -cert /opt/ercd/ssl/server.pem查看证书是不是刚刚创建的，命令如下：

cfssl-certinfo -cert /opt/etcd/ssl/server.pem   #查看证书详情

查看etcd进程是否启动：

ps -ef|grep etcd

查看etcd生成的配置文件：

```
cat /opt/etcd/cfg/etcd

# [Member]

ETCD_NAME="etcd01"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"				#etcd的数据目录
ETCD_LISTEN_PEER_URLS="https://192.168.83.141:2380"		#集群端口2380
ETCD_LISTEN_CLIENT_URLS="https://192.168.83.141:2379"	#数据端口2379

# [Clustering]

ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.83.141:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.83.141:2379"
ETCD_INITIAL_CLUSTER="etcd01=https://192.168.83.141:2380,etcd02=https://192.168.83.142:2380,etcd03=https://192.168.83.143:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"	
ETCD_INITIAL_CLUSTER_STATE="new"


```



#### 第一台etcd部署完成，接下来部署第二台etcd

将/opt/etcd目录拷贝纸其他两台节点：

```
scp -r /opt/etcd/ root@192.168.83.142:/opt/

scp -r /opt/etcd/ root@192.168.83.143:/opt/

scp /usr/lib/systemd/system/etcd.service root@192.168.83.142:/usr/lib/systemd/system

scp /usr/lib/systemd/system/etcd.service root@192.168.83.143:/usr/lib/systemd/system

修改192.168.83.142、192.168.83.143两台etcd的配置文件

```



 vim /opt/etcd/cfg/etcd 

```
ETCD_NAME="etcd02"	#改为当前etcd的名称，这里是etcd02
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"				#etcd的数据目录
ETCD_LISTEN_PEER_URLS="https://192.168.83.142:2380"		#修改当前的IP地址即可
ETCD_LISTEN_CLIENT_URLS="https://192.168.83.141:2379"	#修改当前的IP地址即可

# [Clustering]

ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.83.142:2380"	#修改当前的IP地址即可
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.83.142:2379"		#修改当前的IP地址即可
ETCD_INITIAL_CLUSTER="etcd01=https://192.168.83.141:2380,etcd02=https://192.168.83.142:2380,etcd03=https://192.168.83.143:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
```

##### 加载etcd服务使其生效：

systemctl daemon-reload

启动etcd：

systemctl start etcd

查看日志：

tail -fn 100 /var/log/messages 



##### 测试etcd集群状态：

```
切换到/opt/etcd/ssl目录下执行如下指令：
cd /opt/etcd/ssl
然后执行：
/opt/etcd/bin/etcdctl --ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem  --endpoints="https://192.168.83.141:2379,https://192.168.83.142:2379,https://192.168.83.143:2379"  cluster-health

出现如下信息，表示集群正常：
[root@MASTER-1 etcd-cert]# /opt/etcd/bin/etcdctl --ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem  --endpoints="https://192.168.83.141:2379,https://192.168.83.142:2379,https://192.168.83.143:2379"  cluster-health
member 2e86f29f2028fb42 is healthy: got healthy result from https://192.168.83.141:2379
member 8fac9564024a1f9d is healthy: got healthy result from https://192.168.83.142:2379
member c864fb1a7269dff1 is healthy: got healthy result from https://192.168.83.143:2379
cluster is healthy
```



## NODE节点安装docker

安装依赖包：yum install yum-utils device-mapper-persistent-data lvm2 -y 

下载docker软件包源：

​	yum-config-manager --add-repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

安装docker-ce

​	yum install docker-ce  -y

启动docker服务：

​	systemctl start  docker

设置开机启动docker

​	systemctl  enable  docker

配置镜像加速器（即国内源）

​	curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://f1361db2.m.daocloud.io



## Flannel容器集群网络部署

准备flannel软件包：flannel-v0.11.0-linux-amd64.tar.gz



在MASTER节点上执行如下命令：

切换到目录： cd /opt/etcd/ssl/

执行如下命令：

```
 /opt/etcd/bin/etcdctl --ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem  --endpoints="https://192.168.83.141:2379,https://192.168.83.142:2379,https://192.168.83.143:2379"  set /coreos.com/network/config '{ "Network": "172.17.1.0/16", "Backend": {"Type": "vxlan"}}'
 
 查看下是否成功：
  /opt/etcd/bin/etcdctl --ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem  --endpoints="https://192.168.83.141:2379,https://192.168.83.142:2379,https://192.168.83.143:2379"  get /coreos.com/network/config '{ "Network": "172.17.1.0/16", "Backend": {"Type": "vxlan"}}'
  
```

Flannel只要部署在NODE节点上即可；

tar -xf flannel-v0.11.0-linux-amd64.tar.gz

解压后会有这几个文件：flanneld  , mk-docker-opts.sh  ,README.md

创建kubernetes目录，将K8S所有的组件都部署在这个目录下：

mkdir -p /opt/kubernetes/{cfg,bin,ssl}

 将flanneld ，mk-docker-opts.sh两个文件移动到/opt/kubernetes/bin/目录下

mv  flanneld mk-docker-opts.sh /opt/kubernetes/bin/

### 执行flannel.sh脚本

#### flannel.sh脚本内容如下：

```
#!/bin/bash

ETCD_ENDPOINTS=${1:-"http://127.0.0.1:2379"}  #需要$1传参，否则默认是：http://127.0.0.1:2379

cat <<EOF >/opt/kubernetes/cfg/flanneld

FLANNEL_OPTIONS="--etcd-endpoints=${ETCD_ENDPOINTS} \
-etcd-cafile=/opt/etcd/ssl/ca.pem \
-etcd-certfile=/opt/etcd/ssl/server.pem \
-etcd-keyfile=/opt/etcd/ssl/server-key.pem"

EOF

cat <<EOF >/usr/lib/systemd/system/flanneld.service
[Unit]
Description=Flanneld overlay address etcd agent
After=network-online.target network.target
Before=docker.service

[Service]
Type=notify
EnvironmentFile=/opt/kubernetes/cfg/flanneld
ExecStart=/opt/kubernetes/bin/flanneld --ip-masq \$FLANNEL_OPTIONS
ExecStartPost=/opt/kubernetes/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/subnet.env
Restart=on-failure

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl enable flanneld
systemctl restart flanneld
```



执行脚本：

```
sh flannel.sh https://192.168.83.141:2379,https://192.168.83.142:2379,https://192.168.83.143:2379

https://192.168.83.141:2379,https://192.168.83.142:2379,https://192.168.83.143:2379为脚本的第一个参数，如果不加这个参数默认为：127.0.0.1
```

查看进程是否启动flannel：

```
ps -ef|grep  flannel 

[root@NODE-1 ~]# ps -ef|grep flannel
root       3880      1  1 21:23 ?        00:00:00 /opt/kubernetes/bin/flanneld --ip-masq --etcd-endpoints=https://192.168.83.141:2379,https://192.168.83.142:2379,https://192.168.83.143:2379 -etcd-cafile=/opt/etcd/ssl/ca.pem -etcd-certfile=/opt/etcd/ssl/server.pem -etcd-keyfile=/opt/etcd/ssl/server-key.pem

如上进程看到引用了刚刚设置的参数，和etcd的证书；
```

##### 到此flannel已部署完毕，

##### 修改docker的配置文件，让它与flannel的网络进行整合，让docker使用flannel的子网：

vim  /usr/lib/systemd/system/docker.service添加如下两行：

```
EnvironmentFile=/run/flannel/subnet.env 
ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS 

#以上两行是为了让docker使用flannel网络的配置，可以cat /run/flannel/subnet.env 查看flannel的子网
```

##### docker配置文件如下：

```
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
BindsTo=containerd.service
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify

# the default is not to use systemd for cgroups because the delegate issues still

# exists and systemd currently does not support the cgroup feature set required

# for containers run by docker

EnvironmentFile=/run/flannel/subnet.env   #添加了这两行，cat /run/flannel/subnet.env 查看子网
ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS 	 #添加了这两行，这两行默认是没有的

# ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock

#ExecStart=/usr/bin/dockerd  	#注意：如果有两个ExecStart参数会报错；
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.

# Both the old, and new location are accepted by systemd 229 and up, so using the old location

# to make them work for either version of systemd.

StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.

# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make

# this option work for either version of systemd.

StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead

# in the kernel. We recommend using cgroups to do container-local accounting.

LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.

# Only systemd 226 and above support this option.

TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers

Delegate=yes

# kill only the docker process, not all processes in the cgroup

KillMode=process

[Install]
WantedBy=multi-user.target
```

##### 配置完之后重启docker即可；

systemctl daemon-reload   重新加载下配置文件

systemctl  restart docker

查看flannel网卡和docker0网卡

ifconfig

#### 注意：docker0和flannel网卡的网段必须是同一个网段的，否则会有问题；

```
docker0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
        inet 172.17.91.1  netmask 255.255.255.0  broadcast 172.17.91.255
        inet6 fe80::42:6eff:fe36:8aa6  prefixlen 64  scopeid 0x20<link>
        ether 02:42:6e:36:8a:a6  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 8  bytes 648 (648.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ens33: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.83.142  netmask 255.255.255.0  broadcast 192.168.83.255
        inet6 fe80::a585:152f:a6a0:8b78  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:74:f1:2f  txqueuelen 1000  (Ethernet)
        RX packets 475732  bytes 240182836 (229.0 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 358060  bytes 41857495 (39.9 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

flannel.1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
        inet 172.17.91.0  netmask 255.255.255.255  broadcast 0.0.0.0
        inet6 fe80::140c:baff:fec9:6094  prefixlen 64  scopeid 0x20<link>
        ether 16:0c:ba:c9:60:94  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 8 overruns 0  carrier 0  collisions 0
```

#### 部署第二台NODE节点的flannel网络，只要把NODE1的文件和配置文件拷贝过来即可

```
指令如下：

scp -r /opt/kubernetes/ root@192.168.83.143:/opt/

scp /usr/lib/systemd/system/docker.service root@192.168.83.143://usr/lib/systemd/system/

scp /usr/lib/systemd/system/flanneld.service root@192.168.83.143://usr/lib/systemd/system/
```

##### 加载配置文件：

systemctl daemon-reload

##### 启动flannel服务：

systemctl start flanneld

##### 重启docker服务：

systemctl  restart  docker

##### 查看docker0网卡和flannel1网卡网段是否在同一个网段，



#### 测试NODE1和NODE2的flannel网段是否能通，能ping通代表没问题

NODE1pingNODE2

##### 启动容器测试：

docker run -it busybox

```
[root@NODE-1 ~]# ping -c2 172.17.26.1
PING 172.17.26.1 (172.17.26.1) 56(84) bytes of data.
64 bytes from 172.17.26.1: icmp_seq=1 ttl=64 time=0.546 ms
64 bytes from 172.17.26.1: icmp_seq=2 ttl=64 time=3.29 ms

--- 172.17.26.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1000ms
rtt min/avg/max/mdev = 0.546/1.921/3.297/1.376 ms
```

NODE2pingNODE1

##### 启动容器测试：

docker run -it busybox

或

```
[root@NODE-2 ~]# ping -c2 172.17.91.1
PING 172.17.91.1 (172.17.91.1) 56(84) bytes of data.
64 bytes from 172.17.91.1: icmp_seq=1 ttl=64 time=0.625 ms
64 bytes from 172.17.91.1: icmp_seq=2 ttl=64 time=0.571 ms

--- 172.17.91.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.571/0.598/0.625/0.027 ms


```

测试成功，flannel网络就部署完成：



## 部署kubernetes  MASTER01组件

##### 解压master.zip包有三个脚本分别是：apiserver.sh、scheduler.sh、controller-manager.sh

##### 1、apiserver.sh 内容如下：

```
# !/bin/bash

MASTER_ADDRESS=$1
ETCD_SERVERS=$2

cat <<EOF >/opt/kubernetes/cfg/kube-apiserver

KUBE_APISERVER_OPTS="--logtostderr=true \\
--v=4 \\
--etcd-servers=${ETCD_SERVERS} \\
--bind-address=${MASTER_ADDRESS} \\
--secure-port=6443 \\
--advertise-address=${MASTER_ADDRESS} \\
--allow-privileged=true \\
--service-cluster-ip-range=10.0.0.0/24 \\
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction \\
--authorization-mode=RBAC,Node \\
--kubelet-https=true \\
--enable-bootstrap-token-auth \\
--token-auth-file=/opt/kubernetes/cfg/token.csv \\
--service-node-port-range=30000-50000 \\
--tls-cert-file=/opt/kubernetes/ssl/server.pem  \\
--tls-private-key-file=/opt/kubernetes/ssl/server-key.pem \\
--client-ca-file=/opt/kubernetes/ssl/ca.pem \\
--service-account-key-file=/opt/kubernetes/ssl/ca-key.pem \\
--etcd-cafile=/opt/etcd/ssl/ca.pem \\
--etcd-certfile=/opt/etcd/ssl/server.pem \\
--etcd-keyfile=/opt/etcd/ssl/server-key.pem"

EOF

cat <<EOF >/usr/lib/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-apiserver
ExecStart=/opt/kubernetes/bin/kube-apiserver \$KUBE_APISERVER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-apiserver
systemctl restart kube-apiserver
```

##### 2、scheduler.sh 内容如下：

```
# !/bin/bash

MASTER_ADDRESS=$1

cat <<EOF >/opt/kubernetes/cfg/kube-scheduler

KUBE_SCHEDULER_OPTS="--logtostderr=true \\
--v=4 \\
--master=${MASTER_ADDRESS}:8080 \\
--leader-elect"

EOF

cat <<EOF >/usr/lib/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-scheduler
ExecStart=/opt/kubernetes/bin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-scheduler
systemctl restart kube-scheduler
```

##### 3、controller-manager.sh 内容如下：

```
# !/bin/bash

MASTER_ADDRESS=$1

cat <<EOF >/opt/kubernetes/cfg/kube-controller-manager

KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=true \\
--v=4 \\
--master=${MASTER_ADDRESS}:8080 \\
--leader-elect=true \\
--address=127.0.0.1 \\
--service-cluster-ip-range=10.0.0.0/24 \\
--cluster-name=kubernetes \\
--cluster-signing-cert-file=/opt/kubernetes/ssl/ca.pem \\
--cluster-signing-key-file=/opt/kubernetes/ssl/ca-key.pem  \\
--root-ca-file=/opt/kubernetes/ssl/ca.pem \\
--service-account-private-key-file=/opt/kubernetes/ssl/ca-key.pem \\
--experimental-cluster-signing-duration=87600h0m0s"

EOF

cat <<EOF >/usr/lib/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-controller-manager
ExecStart=/opt/kubernetes/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl restart kube-controller-manager


```

建议将内容保存为脚本后面会用到



#### 创建kubernetes目录

mkdir -p /opt/kubernetes/{cfg,bin,ssl}

#### 生成 apiserver 证书

创建目录：k8s-cert

mkdir k8s-cert

cd  k8s-cert

拷贝k8s-cert.sh到当前目录

k8s-cert.sh  内容如下：

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
            "ST": "Beijing",
      	    "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

# -----------------------

cat > server-csr.json <<EOF
{
    "CN": "kubernetes",
    "hosts": [				
      "10.0.0.1",
      "127.0.0.1",
      "192.168.83.140",		#master2的IP
      "192.168.83.141",		#master1的IP
      "192.168.83.135",		#LB  负载均衡的IP，预留
      "192.168.83.254",		#VIP  （虚拟IP）
      "192.168.83.136",		#  预留IP			#其他均无需修改
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "BeiJing",
            "ST": "BeiJing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server

# -----------------------

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "ST": "BeiJing",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

# -----------------------

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "ST": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
```

##### 脚本内容与生成etcd证书的基本一致：主要修改hosts IP地址

保存后直接执行脚本生成：

 sh k8s-cert.sh 

##### 脚本执行后会生成如下文件：

```
admin.csr       admin.pem       ca-csr.json  k8s-cert.sh          kube-proxy-key.pem  server-csr.json
admin-csr.json  ca-config.json  ca-key.pem   kube-proxy.csr       kube-proxy.pem      server-key.pem
admin-key.pem   ca.csr          ca.pem       kube-proxy-csr.json  server.csr          server.pem
```

##### 将需要用到的证书拷贝到/opt/kubernetes/ssl/ 目录下

```
cp ca*pem serve*pem /opt/kubernetes/ssl/
```

cd ..

解压kubernetes-server-linux-amd64.tar.gz文件：

tar  -xf  kubernetes-server-linux-amd64.tar.gz

cd  kubernetes/server/bin

##### 将刚刚解压出来的server/bin目录下的二进制文件拷贝至/opt/kubernetes/bin/目录下

cp kube-apiserver kube-scheduler kube-controller-manager kubectl  /opt/kubernetes/bin/

##### 创建一个token文件：

```
 vim /opt/kubernetes/cfg/token.csv     #加入如下内容：

0fb61c46f8991b718eb38d27b605b008,kubelet-bootstrap,10001,"system:kubelet-bootstrap"
```

保存退出即可

**token介绍：**

```
0fb61c46f8991b718eb38d27b605b008：# token ID, 是随机生成的一个字符串，可使用：head -c 16 /dev/urandom | od -An -t x | tr -d ' '  来生成，官方推荐的方法；

kubelet-bootstrap： #用户

10001：#用户ID

"system:kubelet-bootstrap"： #绑定的角色
```



**执行apiserver脚本命令如下：**

 切换目录下：

cd master

```
sh apiserver.sh 192.168.83.141 https://192.168.83.141:2379,https://192.168.83.142:2379,https://192.168.83.143:2379
```

**查看apiserver是否启动：**

ps -ef|grep kube-apiserver

执行scheduler.sh脚本，

scheduler.sh脚本内容如下：

```
# !/bin/bash

MASTER_ADDRESS=$1

cat <<EOF >/opt/kubernetes/cfg/kube-scheduler

KUBE_SCHEDULER_OPTS="--logtostderr=true \\
--v=4 \\
--master=${MASTER_ADDRESS}:8080 \\
--leader-elect"

EOF

cat <<EOF >/usr/lib/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-scheduler
ExecStart=/opt/kubernetes/bin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-scheduler
systemctl restart kube-scheduler
```

sh scheduler.sh  127.0.0.1

**查看kube-scheduler进程是否启动：**

ps -ef|grep kube-scheduler



执行：controller-manager脚本内容如下：

```
# !/bin/bash

MASTER_ADDRESS=$1

cat <<EOF >/opt/kubernetes/cfg/kube-controller-manager

KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=true \\
--v=4 \\
--master=${MASTER_ADDRESS}:8080 \\
--leader-elect=true \\
--address=127.0.0.1 \\
--service-cluster-ip-range=10.0.0.0/24 \\
--cluster-name=kubernetes \\
--cluster-signing-cert-file=/opt/kubernetes/ssl/ca.pem \\
--cluster-signing-key-file=/opt/kubernetes/ssl/ca-key.pem  \\
--root-ca-file=/opt/kubernetes/ssl/ca.pem \\
--service-account-private-key-file=/opt/kubernetes/ssl/ca-key.pem \\
--experimental-cluster-signing-duration=87600h0m0s"

EOF

cat <<EOF >/usr/lib/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-controller-manager
ExecStart=/opt/kubernetes/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl restart kube-controller-manager
```

**执行脚本：**

sh controller-manager.sh 127.0.0.1

**查看进程：**

ps  -ef |grep  kube-controller-manager

查看当前master的集群状态：

/opt/kubernetes/bin/kubectl get cs

```
[root@MASTER-1 master]# /opt/kubernetes/bin/kubectl get cs
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok                  
controller-manager   Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
etcd-1               Healthy   {"health":"true"}   
etcd-2               Healthy   {"health":"true"}  
```

#### 到此master节点就部署好了；



#### master上生成node节点的配置文件：

##### kubeconfig.sh脚本内容如下：

```
APISERVER=$1
SSL_DIR=$2

# 创建kubelet bootstrapping kubeconfig 
export KUBE_APISERVER="https://$APISERVER:6443"

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=$SSL_DIR/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=0fb61c46f8991b718eb38d27b605b008 \ #将之前的tokenID写到这里来
  --kubeconfig=bootstrap.kubeconfig

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig

#----------------------

# 创建kube-proxy kubeconfig文件

kubectl config set-cluster kubernetes \
  --certificate-authority=$SSL_DIR/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
  --client-certificate=$SSL_DIR/kube-proxy.pem \
  --client-key=$SSL_DIR/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

```

##### 以上脚本主要生成两个配置文件：kubelet bootstrapping kubeconfig 和kube-proxy kubeconfig

##### 为了方便使用命令设置个环境变量，把如下代码追加到/etc/profile文件末尾即可；

export PATH=$PATH:/opt/kubernetes/bin

source /etc/profile

##### 执行kubeconfig.sh 脚本：

sh kubeconfig.sh  192.168.83.141  /root/k8s/k8s-cert   注意：脚本第一个参数写master的IP地址亦就是本机IP即可，  第二个参数写证书目录：/root/k8s/k8s-cert 就是刚刚生成的证书目录

##### 输出如下表示成功：

```
[root@MASTER-1 kubeconfig]# sh kubeconfig.sh 192.168.83.141 /root/k8s/k8s-cert
Cluster "kubernetes" set.
User "kubelet-bootstrap" set.
Context "default" created.
Switched to context "default".
Cluster "kubernetes" set.
User "kube-proxy" set.
Context "default" created.
Switched to context "default".
```

##### 在当期目录下生成两个配置文件：

```
[root@MASTER-1 kubeconfig]# ll
总用量 16
-rw------- 1 root root 2181 11月  9 21:24 bootstrap.kubeconfig
-rw-r--r-- 1 root root 1351 11月  9 21:17 kubeconfig.sh
-rw------- 1 root root 6283 11月  9 21:24 kube-proxy.kubeconfig
```

##### 将配置文件拷贝到node节点：

scp bootstrap.kubeconfig kube-proxy.kubeconfig root@192.168.83.142:/opt/kubernetes/cfg/

scp bootstrap.kubeconfig kube-proxy.kubeconfig root@192.168.83.143:/opt/kubernetes/cfg/

##### 创建用户：

```
kubectl create clusterrolebinding kubelet-bootstrap  --clusterrole=system:node-bootstrapper  --user=kubelet-bootstrap
```



## NODE节点部署：

##### 在master节点上解压的kubernetes-server-linux-amd64.tar.gz文件目录中拷贝执行文件到NODE节点

```
cd kubernetes/server/bin/

scp kubelet kube-proxy root@192.168.83.142:/opt/kubernetes/bin/

scp kubelet kube-proxy root@192.168.83.143:/opt/kubernetes/bin/
```



##### 上传node.zip包到node节点

解压node.zip包：

unzip node.zip

kubelet.sh 脚本文件内容：

```
# !/bin/bash

NODE_ADDRESS=$1
DNS_SERVER_IP=${2:-"10.0.0.2"}

cat <<EOF >/opt/kubernetes/cfg/kubelet

KUBELET_OPTS="--logtostderr=true \\
--v=4 \\
--hostname-override=${NODE_ADDRESS} \\
--kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \\
--bootstrap-kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig \\
--config=/opt/kubernetes/cfg/kubelet.config \\
--cert-dir=/opt/kubernetes/ssl \\
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0"

EOF

cat <<EOF >/opt/kubernetes/cfg/kubelet.config

kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: ${NODE_ADDRESS}
port: 10250
readOnlyPort: 10255
cgroupDriver: cgroupfs
clusterDNS:

- ${DNS_SERVER_IP} 
  clusterDomain: cluster.local.
  failSwapOn: false
  authentication:
  anonymous:
    enabled: true
  EOF

cat <<EOF >/usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kubelet
ExecStart=/opt/kubernetes/bin/kubelet \$KUBELET_OPTS
Restart=on-failure
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet
```

##### 执行脚本：

sh kubelet.sh 192.168.83.142

##### 查看进程：

ps -ef|grep  kubelet

```
root      15803      1  1 21:51 ?        00:00:00 /opt/kubernetes/bin/kubelet --logtostderr=true --v=4 --hostname-override=192.168.83.142 --kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig --bootstrap-kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig --config=/opt/kubernetes/cfg/kubelet.config --cert-dir=/opt/kubernetes/ssl --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0
```

如上信息表示启动成功；



#### 在master节点上执行：kubectl get csr也可以看到这个node节点等待签名的信息：

```
[root@MASTER-1 kubeconfig]# kubectl get csr
NAME                                                   AGE   REQUESTOR           CONDITION
node-csr-0QZC0WYOYAEGGCX8S4pE_T6vjUeI6tcw31weK9kkX94   95s   kubelet-bootstrap   Pending
```

注解：csr 是证书请求签名；

##### 执行签名请求：

```
kubectl  certificate  approve  node-csr-0QZC0WYOYAEGGCX8S4pE_T6vjUeI6tcw31weK9kkX94

命令参数详解：kubectl  

参数1：certificate  #修改 certificate 资源

参数2：approve 	#同意一个自签证书请求

参数3：就是刚刚kubectl get csr获取到等待签名的NAME名称
```

在执行：kubectl get csr

```
[root@MASTER-1 kubeconfig]# kubectl get csr           
NAME                                                   AGE   REQUESTOR           CONDITION
node-csr-0QZC0WYOYAEGGCX8S4pE_T6vjUeI6tcw31weK9kkX94   11m   kubelet-bootstrap   Approved,Issued
```

看到如上Approved,Issued  同意发布信息表示成功；

##### 再查看node节点状态：

kubectl  get node

```
[root@MASTER-1 kubeconfig]# kubectl get node 
NAME             STATUS   ROLES    AGE   VERSION
192.168.83.142   Ready    <none>   10m   v1.12.2
```

看到如上信息表示node节点以及加入到集群了

### NODE节点部署proxy

执行安装kube-proxy

```
sh proxy.sh 192.168.83.142
```

proxy.sh脚本内容：

```
# !/bin/bash

NODE_ADDRESS=$1

cat <<EOF >/opt/kubernetes/cfg/kube-proxy

KUBE_PROXY_OPTS="--logtostderr=true \\
--v=4 \\
--hostname-override=${NODE_ADDRESS} \\
--cluster-cidr=10.0.0.0/24 \\
--proxy-mode=ipvs \\
--masquerade-all=true \\
--kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig"

EOF

cat <<EOF >/usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-proxy
ExecStart=/opt/kubernetes/bin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-proxy
systemctl restart kube-proxy
```

##### 查看kube-proxy进程：

ps -ef|grep kube-proxy 		看到如下信息表示启动成功；

```
[root@NODE-1 ~]# ps -ef|grep kube-proxy
root      33876      1  0 23:00 ?        00:00:00 /opt/kubernetes/bin/kube-proxy --logtostderr=true --v=4 --hostname-override=192.168.83.142 --cluster-cidr=10.0.0.0/24 --proxy-mode=ipvs --kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig
```





## 部署第二个NODE节点：

##### 在NODE1节点上面将配置好的文件直接拷贝过去NODE2，整个kubernetes目录拷贝过去NODE2节点

```
scp -r /opt/kubernetes/ root@192.168.83.143:/opt/

scp /usr/lib/systemd/system/{kubelet,kube-proxy}.service  root@192.168.83.143:/usr/lib/systemd/system
```

#### 在NODE2节点上修改一下配置文件：

删除/opt/kubernetes/ssl目录下的所有文件：#因为该目录下是刚刚master办法给NODE1的文件；

cd  /opt/kubernetes/ssl

rm -rf *

cd /opt/kubernetes/cfg/

##### 1、修改kubelet配置文件

```
vim kubelet

KUBELET_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=192.168.83.143 \	#改为NODE2的IP地址即可；
--kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \
--bootstrap-kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig \
--config=/opt/kubernetes/cfg/kubelet.config \
--cert-dir=/opt/kubernetes/ssl \
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0"
```

##### 2、修改kubelet.config配置文件：

```
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 192.168.83.143		#改为NODE2的IP地址即可；
port: 10250
readOnlyPort: 10255
cgroupDriver: cgroupfs
clusterDNS:

-10.0.0.2
clusterDomain: cluster.local.
failSwapOn: false
authentication:
anonymous:
  enabled: true

```

##### 3、修改kube-proxy

```
vim kube-proxy
KUBE_PROXY_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=192.168.83.143 \	#改为NODE2的IP地址即可；
--cluster-cidr=10.0.0.0/24 \
--proxy-mode=ipvs \
--masquerade-all=true \				#为ipvsadm使用的，安装了ipvsadm必须要加这个参数
--kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig"
```

##### 启动服务：

```
systemctl start kubelet

​	systemctl enable  kubelet

systemctl  start  kube-proxy

​	systemctl  enable  kube-proxy
```

##### 查看进程，正常启动是没有问题的



#### 到master节点上面get一下：

kubectl  get csr

```
[root@MASTER-1 kubeconfig]# kubectl get csr
NAME                                                   AGE     REQUESTOR           CONDITION
node-csr-0QZC0WYOYAEGGCX8S4pE_T6vjUeI6tcw31weK9kkX94   94m     kubelet-bootstrap   Approved,Issued
node-csr-SnZ9ZG_c1V_1q68Oz2BclHQu0QrgaTcZBmrFyBBYu3M   4m11s   kubelet-bootstrap   Pending
```

如上信息看到NODE2节点已经加入进来了



##### 为NODE2节点授权一下：

kubectl  certificate  approve  node-csr-SnZ9ZG_c1V_1q68Oz2BclHQu0QrgaTcZBmrFyBBYu3M

再执行一下：kubectl get csr

```
[root@MASTER-1 kubeconfig]# kubectl get csr
NAME                                                   AGE     REQUESTOR           CONDITION
node-csr-0QZC0WYOYAEGGCX8S4pE_T6vjUeI6tcw31weK9kkX94   98m     kubelet-bootstrap   Approved,Issued
node-csr-SnZ9ZG_c1V_1q68Oz2BclHQu0QrgaTcZBmrFyBBYu3M   7m32s   kubelet-bootstrap   Approved,Issued
```

看到如上信息授权成功；

##### 查看下NODE节点：

kubectl get node

```
[root@MASTER-1 kubeconfig]# kubectl get node
NAME             STATUS   ROLES    AGE    VERSION
192.168.83.142   Ready    <none>   92m    v1.12.2
192.168.83.143   Ready    <none>   107s   v1.12.2
```

看到如上信息，想在两个NODE节点以及加到集群了

# 到此就部署完成了!

#### 增加master02节点，IP地址：192.168.83.140

##### 将 master01的文件拷贝过去master02

```
scp -r /opt/etcd/ root@192.168.83.140:/opt	# master02节点无需启动etcd

scp -r /opt/kubernetes/ root@192.168.83.140:/opt

scp /usr/lib/systemd/system/{kube-apiserver,kube-controller-manager,kube-scheduler}.service root@192.168.83.140:/usr/lib/systemd/system
```

##### 修改一下master02的apiserver的ip

vim  /opt/kubernetes/cfg/kube-apiserver 

```
KUBE_APISERVER_OPTS="--logtostderr=true \
--v=4 \
--etcd-servers=https://192.168.83.141:2379,https://192.168.83.142:2379,https://192.168.83.143:2379 \
--bind-address=192.168.83.140 \		#改为master02的IP即可
--secure-port=6443 \
--advertise-address=192.168.83.140 \	#改为master02的IP即可
--allow-privileged=true \
--service-cluster-ip-range=10.0.0.0/24 \
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction \
--authorization-mode=RBAC,Node \
--kubelet-https=true \
--enable-bootstrap-token-auth \
--token-auth-file=/opt/kubernetes/cfg/token.csv \
--service-node-port-range=30000-50000 \
--tls-cert-file=/opt/kubernetes/ssl/server.pem  \
--tls-private-key-file=/opt/kubernetes/ssl/server-key.pem \
--client-ca-file=/opt/kubernetes/ssl/ca.pem \
--service-account-key-file=/opt/kubernetes/ssl/ca-key.pem \
--etcd-cafile=/opt/etcd/ssl/ca.pem \
--etcd-certfile=/opt/etcd/ssl/server.pem \
--etcd-keyfile=/opt/etcd/ssl/server-key.pem"
```

systemctl daemon-reload

systemctl start kube-apiserver

​	systemctl enable kube-apiserver

systemctl start kube-controller-manager

​	systemctl  enable  kube-controller-manager

systemctl start  kube-scheduler

​	systemctl enable kube-scheduler

### 到此master02节点部署完毕



## 部署LB高可用： 

##### LB：load balance的缩写，负载均衡的意思

IP地址：192.168.83.135、192.168.83.136

```
安装nginx依赖包：

yum install gcc gcc-c++ pcre-devel  openssl openssl-devel -y

下载安装nginx：

wget -c  http://nginx.org/download/nginx-1.16.1.tar.gz

tar -xf nginx-1.16.1.tar.gz

cd nginx-1.16.1

./configure  --prefix=/usr/local/nginx --with-http_ssl_module --with-http_stub_status_module  --with-stream

make && make install
```

配置文件如下：

由于是使用了nginx的四层所以无需http模块；

```
#user  nobody;
worker_processes  1;

events {
    worker_connections  1024;
}


stream {

   log_format  main  '$remote_addr $upstream_addr - [$time_local] $status $upstream_bytes_sent';
    access_log  logs/k8s-access.log  main;

    upstream k8s-apiserver {
        server 192.168.83.140:6443;
        server 192.168.83.141:6443;
    }
    server {
                listen 6443;
                proxy_pass k8s-apiserver;
    }
    }
```

#### 安装keepalived

yum install  keepalived -y

##### 写入如下配置文件：

```
vim /etc/keepalived/keepalived.conf
! Configuration File for keepalived 
 
global_defs { 
   # 接收邮件地址 
   notification_email { 
     acassen@firewall.loc 
     failover@firewall.loc 
     sysadmin@firewall.loc 
   } 
   # 邮件发送地址 
   notification_email_from Alexandre.Cassen@firewall.loc  
   smtp_server 127.0.0.1 
   smtp_connect_timeout 30 
   router_id NGINX_MASTER 
} 

vrrp_script check_nginx {
    script "/usr/local/nginx/sbin/check_nginx.sh"
}

vrrp_instance VI_1 { 
    state MASTER 			#备服需要改为：BACKUP
    interface eth0
    virtual_router_id 51 # VRRP 路由 ID实例，每个实例是唯一的 
    priority 100    # 优先级，备服务器设置 90 
    advert_int 1    # 指定VRRP 心跳包通告间隔时间，默认1秒 
    authentication { 
        auth_type PASS      
        auth_pass 1111 
    }  
    virtual_ipaddress { 
        192.168.83.254/24 
    } 
    track_script {
        check_nginx
    } 
}
```

##### 编写检测nginx脚本

```
vim /usr/local/nginx/sbin/check_nginx.sh

count=$(ps -ef |grep nginx |egrep -cv "grep|$$")

if [ "$count" -eq 0 ];then
    systemctl  stop  keepalived
fi
```

chmod +x /usr/local/nginx/sbin/check_nginx.sh	#给予脚本授权执行权限

#### 备机的安装方法一致，

##### 修改NODE节点配置文件IP

1、修改配置文件：bootstrap.kubeconfig

vim  /opt/kubernetes/cfg/bootstrap.kubeconfig

```
server: https://192.168.83.254:6443		#把这个IP地址改成VIP即可
```

##### 2、修改配置文件：kubelet.kubeconfig

vim  /opt/kubernetes/cfg/kubelet.kubeconfig

```
server: https://192.168.83.254:6443		#把这个IP地址改成VIP即可
```

##### 3、修改配置文件：kube-proxy.kubeconfig 

vim  /opt/kubernetes/cfg/kube-proxy.kubeconfig 

```
server: https://192.168.83.254:6443		#把这个IP地址改成VIP即可
```

##### 修改完三个配置文件后重启：

systemctl restart kubelet

systemctl restart kube-proxy

##### 查看一下刚刚修改的三个文件有没有成功：

```
[root@NODE-1 cfg]# grep 254 *
bootstrap.kubeconfig:    server: https://192.168.83.254:6443
kubelet.kubeconfig:    server: https://192.168.83.254:6443
kube-proxy.kubeconfig:    server: https://192.168.83.254:6443
```

##### 到master节点上创建一个pod测试一下：

kubectl run nginx --image=nginx

```
[root@MASTER-1 ~]# kubectl run nginx --image=nginx
kubectl run --generator=deployment/apps.v1beta1 is DEPRECATED and will be removed in a future version. Use kubectl create instead.
deployment.apps/nginx created
[root@MASTER-1 ~]# kubectl get pods
NAME                    READY   STATUS              RESTARTS   AGE
nginx-dbddb74b8-x96v6   0/1     ContainerCreating   0          14s
[root@MASTER-1 ~]# kubectl get pods
NAME                    READY   STATUS    RESTARTS   AGE
nginx-dbddb74b8-x96v6   1/1     Running   0          23s
```

##### 现在访问pod日志会报错：

kubectl log nginx-dbddb74b8-x96v6

```
[root@MASTER-1 ~]# kubectl log nginx-dbddb74b8-x96v6
log is DEPRECATED and will be removed in a future version. Use logs instead.
Error from server (Forbidden): Forbidden (user=system:anonymous, verb=get, resource=nodes, subresource=proxy) ( pods/log nginx-dbddb74b8-x96v6
```

原因是因为要通过kubectl授权才可以查看日志

##### 解决方法执行如下命令即可：

```
kubectl  create clusterrolebinding  cluster-system-anonymous  --clusterrole=cluster-admin  --user=system:anonymous
```

再查看日志就不报错了：

```
[root@MASTER-1 ~]# kubectl log nginx-dbddb74b8-x96v6
log is DEPRECATED and will be removed in a future version. Use logs instead.
```

##### 查看刚刚创建的pod状态：

kubectl get pods -o wide

```
[root@MASTER-1 ~]# kubectl get pods -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP            NODE             NOMINATED NODE
nginx-dbddb74b8-x96v6   1/1     Running   0          11m   172.17.90.2   192.168.83.142   <none>
```



## 安装dashboard

可以到官网下载如下配置文件：

```
1、dashboard-configmap.yaml

2、dashboard-controller.yaml

3、dashboard-rbac.yaml

4、dashboard-secret.yaml

5、dashboard-service.yaml

6、k8s-admin.yaml

```

执行如下创建命令：

按照如下顺序执行即可：

```
kubectl create -f dashboard-rbac.yaml 

kubectl create -f dashboard-secret.yaml

kubectl create -f dashboard-configmap.yaml

kubectl create -f dashboard-controller.yaml 

kubectl create -f dashboard-service.yaml 
```

查看一下命名空间：

```
kubectl get pods -n kube-system		# -n  是指定命名空间
查看一下service
kubectl get pods,svc -n kube-system		
```

kubectl get pods,svc -n kube-system

```
[root@MASTER-1 dashboard]# kubectl get pods,svc -n kube-system
NAME                                        READY   STATUS    RESTARTS   AGE
pod/kubernetes-dashboard-65f974f565-sjhc5   1/1     Running   0          3m21s

NAME                           TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)         AGE
service/kubernetes-dashboard   NodePort   10.0.0.50    <none>        443:30001/TCP   2m53s
```

#### 接下来在浏览器输入NODE的地址打开：https://192.168.83.142:30001/   即可看到dashboard页面

##### 此时选择令牌验证；



### 创建token： 需要在master节点上执行

kubectl  create  -f  k8s-admin.yaml

##### 查看刚刚创建的token 名称：

kubectl  get  secret  -n  kube-system

```
[root@MASTER-1 dashboard]# kubectl create -f k8s-admin.yaml 
serviceaccount/dashboard-admin created
clusterrolebinding.rbac.authorization.k8s.io/dashboard-admin created
[root@MASTER-1 dashboard]# kubectl  get  secret  -n  kube-system
NAME                               TYPE                                  DATA   AGE
dashboard-admin-token-pf9pd        kubernetes.io/service-account-token   3      3m11s
default-token-fs749                kubernetes.io/service-account-token   3      2d1h
kubernetes-dashboard-certs         Opaque                                0      16m
kubernetes-dashboard-key-holder    Opaque                                2      16m
kubernetes-dashboard-token-2vcr9   kubernetes.io/service-account-token   3      15m
```

##### 根据上面的token名称查看token

kubectl  describe  secret  dashboard-admin-token-pf9pd  -n kube-system

token的内容如下：

```
[root@MASTER-1 dashboard]# kubectl  describe  secret  dashboard-admin-token-pf9pd  -n kube-system
Name:         dashboard-admin-token-pf9pd
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: dashboard-admin
              kubernetes.io/service-account.uid: fbf6c51d-048c-11ea-be3c-000c29100356

Type:  kubernetes.io/service-account-token

# Data

token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJkYXNoYm9hcmQtYWRtaW4tdG9rZW4tcGY5cGQiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGFzaGJvYXJkLWFkbWluIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiZmJmNmM1MWQtMDQ4Yy0xMWVhLWJlM2MtMDAwYzI5MTAwMzU2Iiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmUtc3lzdGVtOmRhc2hib2FyZC1hZG1pbiJ9.FpMnpCnAYLa1_wK83MWCbixsbq-fHqh_yXQQEwG0GzU-o3WeykBWEjS-PZx_OEPzfcm7L9pjNHyRzmf0hiPRrxUOVheIvTt-F5jxgG-riYio3K9Ot9tTBq6Jp36S78l4NOcyXcRxW59iEteUACN2SfrJsFwzYklcmMoxXLjKIgZfo9ZT10wj6V3yK_C84Nx_3lGDU_WAkkcW1KKSj7JWKAcKnHTF6VEqwotc46h7E8vLeM7hPeYYIUtVWVCCywyDG5W1OPgEeziLCdjCpTgxKMU5OvrNuiD5yd79rrRWimZ-Z4r95O9EpN_BuzqfqZesU-WPAip4JDWCn1aFSJJHqg
ca.crt:     1359 bytes
namespace:  11 bytes
```

### 将token粘贴到dashboard验证一下就可以登录dashboard页面了

### 到此K8S就大功告成了！

----------------------------------------------



## 自签证书：

##### 由于k8s初始证书有问题导致有些浏览器打不开无法访问dashboard页面：

脚本内容如下：

dashboard-cert.sh

```
cat > dashboard-csr.json <<EOF
{
    "CN": "Dashboard",
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


K8S_CA=$1
cfssl gencert  -ca=$K8S_CA/ca.pem -ca-key=$K8S_CA/ca-key.pem -config=$K8S_CA/ca-config.json -profile=kubernetes dashboard-csr.json | cfssljson -b
are dashboard
kubectl  delete secret kubernetes-dashboard-certs -n kube-system
kubectl  create secret generic kubernetes-dashboard-certs --from-file=./ -n kube-system

# dashboard-controller.yaml 增加证书两行，然后apple
#       args:
#         # PLATFORM-SPECIFIC  ARGS HERE
#         - --auto-generate-certificates
#         - --tls-key-file-dashboard-key.prm
#         - --tls-cert-file=dashboard.pem

```

##### 执行：sh dashboard-cert.sh /root/k8s/k8s-cert

```
[root@MASTER-1 dashboard]# sh dashboard-cert.sh /root/k8s/k8s-cert
2019/11/11 23:38:14 [INFO] generate received request
2019/11/11 23:38:14 [INFO] received CSR
2019/11/11 23:38:14 [INFO] generating key: rsa-2048
2019/11/11 23:38:14 [INFO] encoded CSR
2019/11/11 23:38:14 [INFO] signed certificate with serial number 307821579399592877864359066774534969001686559356
2019/11/11 23:38:14 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
secret "kubernetes-dashboard-certs" deleted
secret/kubernetes-dashboard-certs created
```

修改配置文件：dashboard-controller.yaml

##### 在配置文件args中增加两行:

```
	- --tls-key-file=dashboard-key.pem
    - --tls-cert-file=dashboard.pem
```

完整配置文件如下：

      - ```
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          labels:
            k8s-app: kubernetes-dashboard
            addonmanager.kubernetes.io/mode: Reconcile
          name: kubernetes-dashboard
        
        ##   namespace: kube-system
        
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: kubernetes-dashboard
          namespace: kube-system
          labels:
            k8s-app: kubernetes-dashboard
            kubernetes.io/cluster-service: "true"
            addonmanager.kubernetes.io/mode: Reconcile
        spec:
          selector:
            matchLabels:
              k8s-app: kubernetes-dashboard
          template:
            metadata:
              labels:
                k8s-app: kubernetes-dashboard
              annotations:
                scheduler.alpha.kubernetes.io/critical-pod: ''
                seccomp.security.alpha.kubernetes.io/pod: 'docker/default'
            spec:
              priorityClassName: system-cluster-critical
              containers:
        
        - name: kubernetes-dashboard
          image: siriuszg/kubernetes-dashboard-amd64:v1.8.3
          resources:
            limits:
              cpu: 100m
              memory: 300Mi
            requests:
              cpu: 50m
              memory: 100Mi
              ports:
                - containerPort: 8443
                  protocol: TCP
                args:
                  # PLATFORM-SPECIFIC ARGS HERE
                  - --auto-generate-certificates
                  - --tls-key-file=dashboard-key.pem	#刚刚增加的是这两行,指定证书位置
                  - --tls-cert-file=dashboard.pem		#刚刚增加的是这两行，指定证书位置
        
                volumeMounts:
                - name: kubernetes-dashboard-certs
                  mountPath: /certs
                - name: tmp-volume
                  mountPath: /tmp
                livenessProbe:
                  httpGet:
                    scheme: HTTPS
                    path: /
                    port: 8443
                  initialDelaySeconds: 30
                  timeoutSeconds: 30
              volumes:
              - name: kubernetes-dashboard-certs
                secret:
                  secretName: kubernetes-dashboard-certs
              - name: tmp-volume
                emptyDir: {}
              serviceAccountName: kubernetes-dashboard
              tolerations:
              - key: "CriticalAddonsOnly"
                operator: "Exists"
        ```
        
        #### 执行部署命令如下：
        
        kubectl apply -f dashboard-controller.yaml 
        
        #### 显示结果如下表示成功：
        
        ```
        [root@MASTER-1 dashboard]# kubectl apply -f dashboard-controller.yaml 
        Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
        serviceaccount/kubernetes-dashboard configured
        Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
        deployment.apps/kubernetes-dashboard configured
        ```


​        

## 总结步骤：(单master+两个NODE节点)

```
1、部署自签ETCD证书

2、ETCD数据库部署

3、NODE节点安装docker

4、Flannel网络部署  （先写入子网到ETCD）

5、自签apiserver证书

6、部署APIserver组件,包括（token.cvs）

7、部署controller-manager（需要指定apiserver证书) 和scheduler组件

8、生成kubeconfig （bootsrap.kubeconfig和kube-proxy.kubeconfig）

9、部署kublet组件 （创建集群角色）

10、部署kube-proxy组件

11、kubectl  get  csr &&  kubectl  certificate  approve  允许颁发证书，加入集群;

12、增加一个NODE节点（删除已生成的SSL证书，修改kubelet，kubelet.config，kube-proxy里的NODEip）
```



----------------------------------------------------



#### MASTER节点启动：

```
systemctl restart etcd

systemctl start kube-apiserver

systemctl start kube-controller-manager

systemctl start  kube-scheduler
```

#### NODE节点启动顺序：

```
systemctl restart etcd

systemctl restart flanneld

systemctl restart docker

systemctl restart kubelet

systemctl restart kube-proxy
```

