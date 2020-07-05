# CentOS7部署sslvpn服务器

**centos7使用ocserv搭建ciscoanyconnect服务器，使用yum安装**：

**安装epel-release 扩展源**

```
yum -y install epel-release
```

**安装Ocserv**

```
yum  install ocserv -y
```

**新建一个目录，用来存放SSL证书相关文件，然后进入到这个目录内.**

```
mkdir ssl
cd ssl
```

**新建一个证书模板并写入内容：**

```
vim ca.tmpl
cn = "XIAOFEIGE"						#这个名称可以随便定义
organization = "XIAOFEIGE.IM"			#这个名称可以随便定义
serial = 1
expiration_days = 9999
ca
signing_key
cert_signing_key
crl_signing_key
```

**生成私钥和CA证书：**

```
certtool --generate-privkey --outfile ca-key.pem
certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem
```

**生成服务器证书，还是老样子新建一个证书模板并写入内容：**

```
vim server.tmpl
cn = "你的服务器IP"					
organization = "XIAOFEIGE.IM"
expiration_days = 9999
signing_key
encryption_key
tls_www_server

注：cn后面的值改成你的服务器公网IP。
```

**生成服务器私钥和证书：**

```
certtool --generate-privkey --outfile server-key.pem
certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
```

**把证书文件用移动到Ocserv默认的目录下：**

```
cp server-cert.pem /etc/pki/ocserv/public/
cp server-key.pem /etc/pki/ocserv/private/
cp ca-cert.pem /etc/pki/ocserv/cacerts/
```

**修改ocserv的配置文件：**

```
vim /etc/ocserv/ocserv.conf
auth = "plain[passwd=/etc/ocserv/ocpasswd]"
tcp-port = 443
udp-port = 443
banner = "Welcome XIAOFEIGE.IM"
max-clients = 16					#默认是16无需修改
max-same-clients = 2				#默认是2无需修改
server-cert = /etc/pki/ocserv/public/server-cert.pem		#更改服务器证书以及私钥的路径为我们刚才移动的路径
server-key = /etc/pki/ocserv/private/server-key.pem			#更改服务器证书以及私钥的路径为我们刚才移动的路径
ca-cert = /etc/pki/ocserv/cacerts/ca-cert.pem				#更改CA证书的路径为我们刚才移动的路径：
ipv4-network = 192.168.1.0									#去掉#号就是去掉注释，分配给客户端的IP地址段
ipv4-netmask = 255.255.255.0								#去掉#号就是去掉注释
ipv4-netmask = 192.168.1.0/24							    #去掉#号就是去掉注释
tunnel-all-dns = true
dns = 8.8.8.8
dns = 114.114.114.114
```

**创建一个VPN用户：**

```
ocpasswd -c /etc/ocserv/ocpasswd xiaofeige				#用户名：xiaofeige 回车之后会提示输入两遍密码
```

**删除用户可使用如下命令：**

```
ocpasswd -c /etc/ocserv/ocpasswd -d xiaofeig
```

**开启机器的IPV4转发功能：**

```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

**启动CentOS7的Firewalld防火墙：**

```
systemctl start firewalld.service
```

放行Anyconnect的端口（我这里之前设置的是默认的443端口，如果你修改了端口，那么这里也要对应）：

```
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=443/udp
```

**设置转发：**

```
firewall-cmd --permanent --add-masquerade
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

注：eth0是你的公网网卡名字，每台主机的网卡名称可能不一样

**重新加载，让新的配置生效：**

```
firewall-cmd --reload
```

**现在就可以尝试运行一下Ocserv了：**

```
ocserv -f -d 1
```

**正常会显示如下信息：**

```
[root@localhost ssl]# ocserv -f -d 1
note: setting 'plain' as primary authentication method
note: setting 'file' as supplemental config option
listening (TCP) on 0.0.0.0:443...
listening (TCP) on [::]:443...
listening (UDP) on 0.0.0.0:443...
listening (UDP) on [::]:443...
ocserv[21778]: main: initialized ocserv 1.1.0
ocserv[21779]: sec-mod: reading supplemental config from files
ocserv[21779]: sec-mod: sec-mod initialized (socket: /var/lib/ocserv/ocserv.sock.4847dbcd)
```

确定正常后按键盘组合键Ctrl+C退出运行

**设置Ocserv开机启动：**

```
systemctl enable ocserv
systemctl start ocserv
```



参考链接：https://www.jarods.org/419.html

--------------

配置参数详解：

```
# 选择喜欢的登录方式，如果想使用证书登录的话应该把auth="certificate"前的井号删掉并在下面这行的前面加上井号。第5点会提到
auth = "plain[/etc/ocserv/ocpasswd]"

# 允许同时连接的总客户端数量，比如下面的4就是最多只能4台设备同时使用
max-clients = 4

#不同用户用同一个用户名可以同时登录，下面限制的是多少同名用户可以同时使用。改成0就是不作限制
max-same-clients = 2

# ocserv监听的IP地址，千万别动动了就爆炸
#listen-host = [IP|HOSTNAME]

# 服务监听的TCP/UDP端口，如果没有搭网站的话就用TCP443/UDP80好了
tcp-port = 443
udp-port = 80

# 开启以后可以增强VPN性能
try-mtu-discovery = true

# 让服务器读取用户证书（后面会用到用户证书）
cert-user-oid = 2.5.4.3

# 服务器证书与密钥
server-cert = /etc/ssl/selfsigned/server-cert.pem
server-key = /etc/ssl/selfsigned/server-key.pem

# 服务器所使用的dns，我们使用Google提供的DNS
dns = 8.8.8.8
dns = 8.8.4.4

#把route = *全注释掉就是了
#route = 192.168.1.0/255.255.255.0

# 使ocserv兼容AnyConnect
cisco-client-compat = tru
```

## 命令

创建用户

```
ocpasswd -c /etc/ocserv/ocpasswd user
```

删除用户

```
ocpasswd -c /etc/ocserv/ocpasswd -d user
```

启动服务

```
systemctl start ocserv
```

关闭服务器

```
systemctl stop ocserv
```

重启服务

```
systemctl restart ocserv
```

添加开机启动项

```
systemctl enable ocserv
```

