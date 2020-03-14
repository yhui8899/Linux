## socket和内核time_wait优化

Socket是应用层与TCP/IP协议族通信的中间软件抽象层，它是一组接口。在设计模式中，Socket其实就是一个门面模式，它把复杂的TCP/IP协议族隐藏在Socket接口后面，对用户来说，一组简单的接口就是全部，让Socket去组织数据，以符合指定的协议。

​     先从服务器端说起。服务器端先初始化Socket，然后与端口绑定(bind)，对端口进行监听(listen)，调用accept阻塞，等待客户端连接。在这时如果有个客户端初始化一个Socket，然后连接服务器(connect)，如果连接成功，这时客户端与服务器端的连接就建立了。客户端发送数据请求，服务器端接收请求并处理请求，然后把回应数据发送给客户端，客户端读取数据，最后关闭连接，一次交互结束。



#### TCP Soket是一个四元组：

##### 源IP、源端口、目的IP、目的端口



#### 我们使用nc工具来测试一下socket连接：

yum install  nv -y

##### 主机A作为服务器绑定端口：

```
nc -l -4 -p 9999 -k
参数详解：
-l:  listen监听，绑定并监听传入的连接
-4：  ipv4
-p: port 端口
-k:	在侦听模式下接受多个连接,建立连接；
```



##### 主机B作为客户端来连接：

nc  192.168.83.128 9999

```
主机A：
[root@localhost zabbix_agent]# nc -l -4 -p 9999 -k
nihao

客户端：
[root@localhost ~]# nc 192.168.83.128 9999
nihao

#如上可以看到主机A和客户端进行一个实时传输信息；
```



---------------------------------

## time_wait 优化：

##### 有两个参数：为了减少socket的占用，因为socket是有限的，因为端口数有限；

```
1：/proc/sys/net/ipv4/tcp_tw_reuse （reuse复用socket）  
#0：表示关闭，1表示开启：此参数可以打开，当此参数开启的时候tcp_timestamps时间戳必须要开启；

2：/proc/sys/net/ipv4/tcp_timestamps（时间戳）  
#0：表示关闭，1表示开启：默认是开启的， 如果这个时间戳关闭的话 reuse也必须关闭，因为reuse会调用这个时间戳来判断这个数据包是老的还是新的

3： /proc/sys/net/ipv4/tcp_tw_recycle    （快速销毁time_wait）
#0：表示关闭，1表示开启：可以开启，注意：当客户端处于NAT网络的时候不能开启，例如多台客户端通过NAT出网，例如在负载均衡器上是不能开启的，否则会有客户端无法打开网站；

```



---------------------

#### 查看可用的随机端口：

```
cat /proc/sys/net/ipv4/ip_local_port_range 
```



#### 如需要可调整端口范围：

```
echo "10000-61000" >/proc/sys/net/ipv4/ip_local_port_range  即可；
```

------------------------



