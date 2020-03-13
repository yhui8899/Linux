# iptables&firewalld规则

iptables防火墙由表和链构成，其中表示存储在Linux内核的Netfilter模块中，链是存在表中的，链中由单个规则或多个规则组成，Netfilter主要作用于内核空间，属于Linux内核中一个数据包过滤模块，而iptables用于管理Netfilter模块的（管理Netfilter中的表和链规则）。

### IPtables表与链功能

```
Iptables的规则链分为三种：输入、转发和输出。
输入：这条链用来过滤目的地址是本机的连接。例如，如果一个用户试图使用SSH登陆到你的PC/服务器，iptables会首先匹配其IP地址和端口到iptables的输入链规则。
--------------------------------------
转发：这条链用来过滤目的地址和源地址都不是本机的连接。例如，路由器收到的绝大数数据均需要转发给其它主机。如果你的系统没有开启类似于路由器的功能，如NATing，你就不需要使用这条链。
--------------------------------------
输出：这条链用来过滤源地址是本机的连接。例如，当你尝试ping baidu.com时，iptables会检查输出链中与ping和baidu.com相关的规则，然后决定允许还是拒绝你的连接请求。
--------------------------------------------------
注意：当ping一台外部主机时，看上去好像只是输出链在起作用。但是请记住，外部主机返回的数据要经过输入链的过滤。当配置iptables规则时，请牢记许多协议都需要双向通信，所以你需要同时配置输入链和输出链。人们在配置SSH的时候通常会忘记在输入链和输出链都配置它。
```

#### iptables的四张表五条链：

##### 

```
表：raw、mangle、net、filter、#iptables默认表：filter，使用-t参数来指定表例如：iptables -t filter
```

```
链：
INPUT链：		处理来自外部的数据；

OUTPUT链： 	处理向外发送的数据；

FORWARD链： 	将数据转发到本机的其他网卡设备上。

PREROUTING链： 处理刚到达本机并在路由转发前的数据包。它会转换数据包中的目标IP地址（destination ip address），通常用于DNAT(destination NAT)。

POSTROUTING链：处理即将离开本机的数据包。它会转换数据包中的源IP地址（source ip address），通常用于SNAT（source NAT）
```

```
#默认规则：
*filter
:INPUT ACCEPT [0:0]			#默认允许所有访问，生产环境一般只将input设为DROP,其他默认为：ACCEPT；
:FORWARD ACCEPT [0:0]		#默认允许所有转发；
:OUTPUT ACCEPT [0:0]	    #默认允许所有从本机出去，如果设为DROP的话就需要配置两条规则，input和output规则；
	#默认规则，优先级是最低的
```

------------------------

#### 安装iptables：

```
yum install iptable iptables-devel iptables-services iptables-utils -y
```

#### 命令：

```
1.命令：
-A 顺序添加，添加一条新规则
-I 插入，插入一条新规则 -I 后面加一数字表示插入到哪行
-R 修改， 删除一条新规则 -D 后面加一数字表示删除哪行
-D 删除，删除一条新规则 -D 后面加一数字表示删除哪行
-N   新建一个链
-X   删除一个自定义链,删除之前要保证次链是空的,而且没有被引用
-L 查看
 @1.iptables -L -n 以数字的方式显示
 @2. iptables -L -v显示详细信息
 @3. iptables -L -x 显示精确信息
-E   重命名链
-F 清空链中的所有规则
-Z   清除链中使用的规则
-P 设置默认规则
-----------------------------------------------------------
2.匹配条件：
隐含匹配：
   -p  tcp udp icmp
   --sport指定源端口
   --dport指定目标端
   -s 源地址
   -d 目的地址
-i 数据包进入的网卡
-o 数据包出口的网卡
module模块扩展匹配：
	-m state --state   匹配状态的
	-m mutiport --source-port   端口匹配 ,指定一组端口
	-m limit --limit 3/minute   每三分种一次
	-m limit --limit-burst  5   只匹配5个数据包
	-m string --string --algo bm|kmp --string"xxxx"  匹配字符串
	-mtime--timestart 8:00 --timestop 12:00  表示从哪个时间到哪个时间段
	-mtime--days    表示那天
	-m mac --mac-source xx:xx:xx:xx:xx:xx 匹配源MAC地址
	-m layer7 --l7proto qq   表示匹配腾讯qq的 当然也支持很多协议,这个默认是没有的,需要我们给内核打补丁并重新编译内核及iptables才可以使用 -m layer7 这个显示扩展匹配
----------------------------------------------------------
3.动作：
-j
	DROP 直接丢掉
	ACCEPT 允许通过
	REJECT 丢掉，但是回复信息
	LOG --log-prefix"说明信息,自己随便定义" ，记录日志
	SNAT       源地址转换
	DNAT       目标地址转换
	REDIRECT   重定向
	MASQUERAED  地址伪装
	保存iptables规则
	service iptables save
# 重启iptables服务
	service iptables stop
	service iptables start
```

#### 禁止访问80端口：

```
-A INPUT -s 192.168.83.1 -p tcp --dport 80 -j ACCEPT   #允许192.168.83.1地址进来；
-A OUTPUT -s 192.168.83.136 -p tcp --sport 80 -j ACCEPT  #允许从192.168.83.136（本机）出去；
	#注意：output的-s是指向本机，因为是由本机出去的，--sport指本机的源端口出去
	#写完规则后重启：service iptables restart
#参数详解：
	-A：添加一个规则
	-s：source的意思，指向源IP
	-p：指定访问的协议
	--dport：指定访问的端口
	-j：访问的动作，DROP是拒绝访问
```

#### iptables防火墙规则查看：

```
添加拒绝访问111端口规则：
-A INPUT -s 192.168.83.1 -p tcp --dport 111 -j DROP
----------------------------------------------------------------
iptables -L -n
	#参数详解：
	-L：list的意思
	-n：number的意思
----------------------------------------------------------------
[root@localhost ~]# iptables -L -n
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         
DROP       tcp  --  192.168.83.1         0.0.0.0/0            tcp dpt:111
```

#### iptables防火墙规则示例：

```
vim /etc/sysconfig/iptables
-A INPUT -s 192.168.83.1 -p tcp --dport 80 -j DROP		#拒绝访问80端口
-A INPUT -s 192.168.83.1 -p tcp --dport 80 -j ACCEPT	#允许访问80端口
-A INPUT -s 192.168.83.136 -p tcp --sport 80 -j ACCEPT	#允许从本地IP+端口出去
-A INPUT -p tcp --dport 8080 -j ACCEPT					#允许任何人访问8080端口
-A INPUT -p tcp --dport 8080 -j DROP					#拒绝任何人访问8080
----------------------------------------
-A INPUT -p icmp -j DROP					#禁ping，不加-s 指定源地址就是代表所有
-A INPUT -s 192.168.83.1 -p icmp -j DROP	#禁止192.168.83.1主机ping
-A INPUT -p icmp -j ACCEPT					#允许ping
-A INPUT -s 192.168.83.1 -p icmp -j ACCEPT	#允许192.168.83.1主机ping
-A INPUT -s 192.168.83.1 -j DROP 			#禁止通过任何协议访问任何端口
----------------------------------------
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT	
	#必须是NEW建立连接后才会进入这两个状态
	#允许RELATED,ESTABLISHED这两个连接状态的访问所有端口和服务；
	#RELATED：该数据包与本机发出的数据包有关，往外发数据；
	#ESTABLISHED：已建立的链接状态；
-A INPUT -m state --state NEW -m tcp --dport 80 -j ACCEPT
-A INPUT -m state --state NEW -m tcp --dport 443 -j ACCEPT
-A INPUT -m state --state NEW -m tcp --dport 22 -j ACCEPT
	#允许新建的连接访问22端口
-A INPUT -j REJECT --reject-with tcp-host-prohibited
	#REJECT  丢掉，但是回复信息；例如：-A INPUT -p icmp -j REJECT
	#上面的规则没有匹配成功后会禁止INPUT并且会返回一个ICMP的信息
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
	#FORWARD 转发，与上面规则一样会返回一个ICMP的随机信息；
----------------------------------------
使用模块的方式：
-A INPUT -m mac --mac-source 00-50-56-C0-00-08 -p tcp --dport 8080 -j ACCEPT
	#-m  是module模块的意思，使用mac模块，
	#--mac-source 源mac地址；
-A INPUT -m time --timestart 07:00 --timestop 23:00 -p tcp --dport 80 -j ACCEPT
	#表示允许所有主机在07:00至23:00访问服务器的80端口
	
```

#### 交互式配置防火墙规则：

```
iptables -t filter -A INPUT -s 192.168.83.1 -p tcp --dport 8080 -j ACCEPT	
service iptbales save	
	#上面写完规则后要保存方可生效；
	#iptables -t 是table的意思，指定表，默认是：filter
```

-----------------------------------



## firewalld防火墙添加策略：

##### firewalld防火墙开启后默认是拒绝访问的

```
firewall-cmd --add-port=80/tcp --permanent
	#在/etc/firewalld/zones/public.xml文件中生成一条规则：<port protocol="tcp" port="80"/>
firewall-cmd --remove-port=80/tcp --permanent
 	#移除规则
firewall-cmd --add-protocol=icmp --permanent
	#开放ICMP协议
---------------------------------------------------------
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.83.1" port protocol="tcp" port="6379" accept" 
#添加了如下代码：
  <rule family="ipv4">
    <source address="192.168.83.1"/>
    <port protocol="tcp" port="6379"/>
    <accept/>
	#允许192.168.83.1主机访问本机的6379端口
---------------------------------------------------------
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.83.1" port protocol="tcp" port="6379" drop"
#添加了如下代码：
  <rule family="ipv4">
    <source address="192.168.83.1"/>
    <port protocol="tcp" port="6379"/>
    <drop/>
	#拒绝192.168.83.1主机访问本机的6379端口
--------------------------------------------------------
使用修改配置文件的方式去更改防火墙，以服务名的方式添加防火墙策略；
vim /etc/firewalld/zones/public.xml
 <service name="ssh"/>
 <service name="mysql"/>
 <service name="vsftpd"/>
#添加完规则后需要重新加载一下防火墙规则才生效：
 firewall-cmd --reload
--------------------------------------------------------
firewall防火墙以服务方式添加规则默认是读取模板的配置文件：
/usr/lib/firewalld/services
#如果需要添加模板里面没有的服务，可以copy一个模板修改对应端口即可
```

##### firewall防火墙查看帮助信息：firewall-cmd --help|more

#### 查看firewalld当前开放了哪些规则

```
firewall-cmd --list-all
[root@block01 ~]# firewall-cmd --list-all
public
  target: default
  icmp-block-inversion: no
  interfaces: 
  sources: 
  services: ssh dhcpv6-client
  ports: 80/tcp 3306/tcp
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

