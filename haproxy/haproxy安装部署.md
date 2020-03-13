**haproxy源码部署安装：**

haproxy服务器地址：192.168.199.10

后端httpd地址1：192.168.199.100

后端httpd地址2:	192.168.199.101

**1、下载haproxy安装包：**

wget -c https://www.haproxy.org/download/1.8/src/haproxy-1.8.20.tar.gz

tar -xf haproxy-1.8.20.tar.gz

cd  haproxy-1.8.20

make  TARGET=linux26  PREFIX=/usr/local/haproxy/

make  install   PREFIX=/usr/local/haproxy

**2、创建配置文件目录：**

cd /usr/local/haproxy

mkdir  -p etc

touch /usr/local/haproxy/etc/haproxy.cfg

**3、将如下配置写到haproxy.cfg文件中**

global		#全局

	log 127.0.0.1 local3 info	
	maxconn 4096		
	uid 99		
	gid 99	
	daemon								
	nbproc 1						

defaults		#默认

	log  global		
	mode	http			
	maxconn	2048				
	retries	3	
	option redispatch	
	#stats uri /haproxy?stats	
	stats auth admin:123
	timeout connect 5s
	timeout client 50s  
	timeout server 50s
	
	#contimeout 5000	老版本使用;				
	#clitimeout 50000	老版本使用;		
	#srvtimeout 50000	老版本使用;

frontend http-in	#前端（客户端访问）

	bind 0.0.0.0:80			
	mode http		
	log global				
	option httplog			
	option httpclose	
	acl html url_reg -i \.html$		
	use_backend html-server if html	
	default_backend html-server

backend  html-server			#后端（服务器端）
		mode http		
		balance roundrobin 	 #轮询模式（rr）
		option httpchk GET /index.html	#表示GET检查index.html页面
		cookie SERVERID insert indirect nocache	
		server html-A 	192.168.199.100:80  weight 1  cookie 3	check  inter 2000  rise 2  fall  5	
		server html-B	192.168.199.101:80  weight 1  cookie 4 	check  inter 2000  rise 2  fall  5		

**4、启动haproxy：**

/usr/local/haproxy/sbin/haproxy   -f  /usr/local/haproxy/etc/haproxy.cfg



**5、haproxy后台监控地址**：http://192.168.199.10/haproxy?stats



**推荐一款纯文本界面的www浏览器工具**：elinks

 yum install elinks -y

使用方法：

elinks  http://www.baidu.com  则可用纯文本的模式现实百度首页

elinks  --dump  http://192.168.199.10    #将HTML文档以纯文本的方式打印到标准输出设备；

elinks 工具是纯文本模式的浏览器工具，可用于测试使用；







**haproxy工作场景及特点**：

​			HAProxy特别适用于那些负载特大的web站点，这些站点通常又需要会话保持或七层处理。负载均衡LVS是基于四层，新型的大型互联网公司也在采用Haproxy，了解了Haproxy大并发、七层应用等，Haproxy高性能负载均衡优点：
​	1、HAProxy是支持虚拟主机的，可以工作在4、7层；  

​	2、能够补充Nginx的一些缺点比如Session的保持，Cookie的引导等工作；

​	3、支持url检测后端的服务器；

​	4、它跟LVS一样，只是一款负载均衡软件，单纯从效率上来讲HAProxy更会比Nginx有更出色的负载均衡速度，在并发处理上也是优于Nginx的；

​	5、HAProxy可以对Mysql读进行负载均衡，对后端的MySQL节点进行检测和负载均衡，HAProxy的支持多种算法。



**4层：传输层**：接上一层的数据，在必要的时候把数据进行分割，并将这些数据交给网络层，且保证这些数据段有效到达对端；

**7层：应用层**：各种应用程序协议，如：http、ftp、SMTP、pop3等；









