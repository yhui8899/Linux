# CentOS7部署OpenVPN

**安装相关工具**：openvpn、easy-rsa、iptables-server

```
yum install epel-release -y
yum -y install openvpn easy-rsa iptables-services
```

**生成证书及相关文件：**

1、CA根证书

2、openvpn服务器证书

3、Diffie-Hellman算法用到的key 复制easy-rsa脚本到/etc/openvpn下面，该脚本是用来生成CA证书和各种key文件

4、复制easy-rsa脚本到/etc/openvpn下面，该脚本是用来生成CA证书和各种key文件

```
cp -r /usr/share/easy-rsa/ /etc/openvpn/
-----------------------------------------------------------
查看证书版本号：
ls /etc/openvpn/easy-rsa
[root@localhost hello]# ls /etc/openvpn/easy-rsa
3  3.0  3.0.7
------------------------------------------------------------
cd /etc/openvpn/easy-rsa/3.0.7/
vim vars	#写入如下内容：
export KEY_COUNTRY="CN" 		#（国家名称）
export KEY_PROVINCE="GuangDong" 	#（省份名称）
export KEY_CITY="GuangZhou" 		#（城市名称）
export KEY_ORG="XIAOFEIGE" 			#（组织机构名称）
export KEY_EMAIL="355638930@qq.com" #（邮件地址）
保存退出后执行如下命令使变量生效：
source ./vars	
```

**生成CA根证书**

```
./easyrsa init-pki			##初始化 pki 相关目录，会提示在此处初始化新的PKI，在 Confirm removal后面直接输入：yes 回车即可
```

生成 CA 根证书, 输入 Common Name，名字随便起

```
./easyrsa build-ca nopass 
提示如下：
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:xiaofeige		#这里起名：xiaofeige
```

**生成openvpn服务器证书和密钥**，第一个参数是证书名称

```
./easyrsa build-server-full xiaofeige nopass
```

**生成Diffie-Hellman算法需要的密钥文件**

```
./easyrsa gen-dh   #创建 Diffie-Hellman ，时间比较久一些
--------------------------------------------------------------------------------------------------------------------------------
#具体如下面提示信息一样：
[root@localhost 3.0.7]# ./easyrsa gen-dh 
Note: using Easy-RSA configuration from: /etc/openvpn/easy-rsa/3.0.7/vars
Using SSL: openssl OpenSSL 1.0.2k-fips  26 Jan 2017
Generating DH parameters, 2048 bit long safe prime, generator 2
This is going to take a long time
....................................................................+...................................+...................+.......................................................................................................................................................................................................+...................................+...................+...................................................................................................................................
DH parameters of size 2048 created at /etc/openvpn/easy-rsa/3.0.7/pki/dh.pem
```

**生成tls-auth key**，为了防止DDOS和TLS攻击，这个属于可选安全配置

```
openvpn --genkey --secret ta.key
```

**openvpn文件整理**：（将相关的证书Key放copy到certs目录下）

```
mkdir /etc/openvpn/server/certs 

cd /etc/openvpn/server/certs/

cp /etc/openvpn/easy-rsa/3/pki/dh.pem ./  							# SSL 协商时 Diffie-Hellman 算法需要的 key

cp /etc/openvpn/easy-rsa/3/pki/ca.crt ./  							# CA 根证书

cp /etc/openvpn/easy-rsa/3/pki/issued/xiaofeige.crt ./server.crt 	# open VPN 服务器证书

cp /etc/openvpn/easy-rsa/3/pki/private/xiaofeige.key ./server.key 	# open VPN 服务器证书 key

cp /etc/openvpn/easy-rsa/3/ta.key ./								# tls-auth key
```

**创建openvpn日志目录**

```
#创建日志目录
 mkdir -p /var/log/openvpn/
#给予权限
chown openvpn:openvpn /var/log/openvpn
```

**配置OpenVPN**

**创建配置文件**（原配置文件在 /usr/share/doc/openvpn-/sample/sample-config-files ）

```
cd /etc/openvpn/
vim server.conf
port 1194   # 监听的端口号
proto udp   # 服务端用的协议，udp 能快点，所以我选择 udp
dev tun
ca /etc/openvpn/server/certs/ca.crt  #   CA 根证书路径
cert /etc/openvpn/server/certs/server.crt  # open VPN 服务器证书路径
key /etc/openvpn/server/certs/server.key  # open VPN 服务器密钥路径，This file should be kept secret
dh /etc/openvpn/server/certs/dh.pem  # Diffie-Hellman 算法密钥文件路径
tls-auth /etc/openvpn/server/certs/ta.key 0 #  tls-auth key，参数 0 可以省略，如果不省略，那么客户端配置相应的参数该配成 1。如果省略，那么客户端不需要 tls-auth 配置
server 10.8.0.0 255.255.255.0   # 该网段为 open VPN 虚拟网卡网段，不要和内网网段冲突即可。open VPN 默认为 10.8.0.0/24
push "dhcp-option DNS 8.8.8.8"  # DNS 服务器配置，可以根据需要指定其他 ns
push "dhcp-option DNS 8.8.4.4"
push "redirect-gateway def1"   # 客户端所有流量都通过 open VPN 转发，类似于代理开全局
compress lzo
duplicate-cn   # 允许一个用户多个终端连接
keepalive 10 120
#client-config-dir /etc/openvpn/server/ccd # 用户权限控制目录
comp-lzo
persist-key
persist-tun
user openvpn  # open VPN 进程启动用户，openvpn 用户在安装完 openvpn 后就自动生成了
group openvpn
log /var/log/openvpn/server.log  # 指定 log 文件位置
log-append /var/log/openvpn/server.log
status /var/log/openvpn/status.log
verb 3
explicit-exit-notify 1
```

**启用iptables**

```
systemctl start iptables
systemctl enable iptables
iptables -F
```

**添加防火墙规则**

```
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o tun0 -j MASQUERADE
service iptables save
systemctl restart iptables
```

**服务器启用地址转发**

```
echo net.ipv4.ip_forward = 1 >>/etc/sysctl.conf
sysctl -p	看到如下配置
net.ipv4.ip_forward = 1
```

**启动服务：**

```
systemctl start openvpn@server  # 启动
systemctl enable openvpn@server  # 开机自启动
systemctl status openvpn@server  # 查看服务状态
```

-------------------------

## 添加客户端用户：

**创建模版配置文件：**

```
cd /etc/openvpn/client/
vim sample.ovpn
client
proto udp
dev tun
remote 58.211.118.110 1194	#这里填写openvpn的外网地址
ca ca.crt
cert admin.crt
key admin.key
tls-auth ta.key 1
remote-cert-tls server
persist-tun
persist-key
comp-lzo
verb 3
mute-replay-warnings
```

**创建用户脚本**（为了创建用户更方便）

```
vim  ovpn_user.sh
# ! /bin/bash
set -e
OVPN_USER_KEYS_DIR=/etc/openvpn/client/keys
EASY_RSA_VERSION=3
EASY_RSA_DIR=/etc/openvpn/easy-rsa/
PKI_DIR=$EASY_RSA_DIR/$EASY_RSA_VERSION/pki

for user in "$@"
do
  if [ -d "$OVPN_USER_KEYS_DIR/$user" ]; then
    rm -rf $OVPN_USER_KEYS_DIR/$user
    rm -rf  $PKI_DIR/reqs/$user.req
    sed -i '/'"$user"'/d' $PKI_DIR/index.txt
  fi
  cd $EASY_RSA_DIR/$EASY_RSA_VERSION
  # 生成客户端 ssl 证书文件
  ./easyrsa build-client-full $user nopass
  # 整理下生成的文件
  mkdir -p  $OVPN_USER_KEYS_DIR/$user
  cp $PKI_DIR/ca.crt $OVPN_USER_KEYS_DIR/$user/   # CA 根证书
  cp $PKI_DIR/issued/$user.crt $OVPN_USER_KEYS_DIR/$user/   # 客户端证书
  cp $PKI_DIR/private/$user.key $OVPN_USER_KEYS_DIR/$user/  # 客户端证书密钥
  cp /etc/openvpn/client/sample.ovpn $OVPN_USER_KEYS_DIR/$user/$user.ovpn # 客户端配置文件
  sed -i 's/admin/'"$user"'/g' $OVPN_USER_KEYS_DIR/$user/$user.ovpn
  cp /etc/openvpn/server/certs/ta.key $OVPN_USER_KEYS_DIR/$user/ta.key  # auth-tls 文件
  cd $OVPN_USER_KEYS_DIR
  zip -r $user.zip $user
done
exit 0
```

**创建用户执行脚本**，后面跟用户名字，执行成功后会生成证书文件

```
sh ovpn_user.sh apollo		#会出现如下信息证明成功；
-----------------------------------
[root@localhost client]# sh ovpn_user.sh apollo

Note: using Easy-RSA configuration from: /etc/openvpn/easy-rsa/3.0.7/vars
Using SSL: openssl OpenSSL 1.0.2k-fips  26 Jan 2017
Generating a 2048 bit RSA private key
...............+++
...+++
writing new private key to '/etc/openvpn/easy-rsa/3/pki/easy-rsa-21750.Wt7RuM/tmp.dMLg1T'
-----
Using configuration from /etc/openvpn/easy-rsa/3/pki/easy-rsa-21750.Wt7RuM/tmp.egEOzz
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'apollo'
Certificate is to be certified until Oct  8 08:17:25 2022 GMT (825 days)

Write out database with 1 new entries
Data Base Updated

  adding: apollo/ (stored 0%)
  adding: apollo/ca.crt (deflated 29%)
  adding: apollo/apollo.crt (deflated 45%)
  adding: apollo/apollo.key (deflated 23%)
  adding: apollo/apollo.ovpn (deflated 29%)
  adding: apollo/ta.key (deflated 40%)
```

导出压缩包解压后放到客户端目录中即可，压缩包在当前目录的keys目录下

备注：外网防火墙需要映射UDP 1194端口

参考：https://www.cnbugs.com/post-1989.html

--------------

### centos7连接openvpn

**安装openvpn:**

```
yum install openvpn -y
```

安装成功后，客户端不需要特别配置，只要将服务器上生成的证书和客户端配置文件拷贝到客户端配置目录中。

下面是所需的文件列表：

```
cd /etc/openvpn/
[root@localhost openvpn]# ls
apollo.crt 
apollo.key  
apollo.ovpn   
ca.crt 
ta.key
```

如上配置文件在服务端创建用户时会自动生成只需放到客户端配置目录中即可

将上面生成的文件，都上传到：/etc/openvpn/目录下，然后日志输出到：/var/log/openvpn.log。

**后台启动命令：**

```
openvpn --daemon --cd /etc/openvpn --config apollo.ovpn --log-append /var/log/openvpn.log
```

可以查看启动日志：tail -fn 30 /var/log/openvpn.log

centos7客户端连接openvpn参考：https://www.icode9.com/content-3-113422.html

