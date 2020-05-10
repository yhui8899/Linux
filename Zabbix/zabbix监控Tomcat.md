# zabbix监控Tomcat

### 部署安装Tomcat

在部署Tomcat前需要先安装jdk

##### 下载Tomcat软件包，版本：8.5.54

```
https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/v8.5.54/bin/apache-tomcat-8.5.54.tar.gz
```

##### 解压安装Tomcat：

```
tar -xf apache-tomcat-8.5.54.tar.gz
mv apache-tomcat-8.5.54.tar.gz /usr/local/tomcat
```

#### 启动前设置jmx参数

##### 创建setenv.sh文件：

cd  /usr/local/tomcat/bin

vim setenv.sh  创建文件并写入如下内容

```
#!/bin/sh
JAVA_OPTS="$JAVA_OPTS -Xmx1024m -Djava.rmi.server.hostname=192.168.83.131 -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=12345 -Dcom.sun.management.j
mxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
```

注意：文件名不能错，这个是tomcat提供的一个定制参数的钩子，名字不同就找不到了

##### setenv.sh配置文件详解：

```
-Djava.rmi.server.hostname=192.168.83.131----- 192.168.83.131为tomcat所在机器的ip地址。

-Dcom.sun.management.jmxremote---- 开启jmx，jdk1.5之前还要手动开启，现在已经默认开启了，所以可以省略

-Dcom.sun.management.jmxremote.port=12345------jmx的端口

-Dcom.sun.management.jmxremote.authenticate=false-------- 不开启验证

-Dcom.sun.management.jmxremote.ssl=false ----------------------不开启ssl通信
```

##### 授权，赋予执行权限：

```
chmod +x  setenv.sh
```

##### 启动Tomcat：

```
/usr/local/tomcat/bin/startup.sh
```

##### 查看端口：

```
[root@localhost bin]# netstat -tnlp|grep java
tcp6       0      0 :::8080                 :::*                    LISTEN      21311/java          
tcp6       0      0 :::11664                :::*                    LISTEN      21311/java          
tcp6       0      0 :::12345                :::*                    LISTEN      21311/java          
tcp6       0      0 :::1661                 :::*                    LISTEN      21311/java          
tcp6       0      0 127.0.0.1:8005          :::*                    LISTEN      21311/java   
```

### 部署zabbix_java_gateway

##### 下载安装zabbix_java_gateway软件包

```
wget https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/4.2/rhel/7/x86_64/zabbix-java-gateway-4.2.2-1.el7.x86_64.rpm
```

##### 安装zabbix_java_gateway

```
yum install zabbix-java-gateway-4.2.2-1.el7.x86_64.rpm
```

##### 修改配置文件：

vim /etc/zabbix/zabbix_java_gateway.conf

```
LISTEN_IP="192.168.83.131"	#监听的地址
LISTEN_PORT=10052			#默认监听10052
PID_FILE="/var/run/zabbix/zabbix_java.pid"		#PID文件，默认即可
START_POLLERS=5				#启动多少个进程轮训java， 要和java 应用保持一定关系
TIMEOUT=30		#这个时长最好稍微长一些，因为java应用是比较慢的，如果超时时间太短，会导致数据获取不到
```

##### 启动zabbix_java_gateway

```
systemctl start zabbix-java-gateway 
```

##### 查看端口

```
[root@localhost src]# netstat -tnlp|grep 10052
tcp6       0      0 192.168.83.131:10052    :::*                LISTEN      21586/java   
```

### 部署zabbix_agent 

##### 安装zabbix agent 相关依赖包：

```
yum install curl curl-devel net-snmp net-snmp-devel perl-DBI mariadb-devel mysql-devel -y 
```

##### 安装zabbix agent

```
tar -xf zabbix-4.2.1.tar.gz 

cd zabbix-4.2.1/

./configure  --prefix=/usr/local/zabbix  --enable-agent

make && make install

useradd -s /sbin/nologin/ zabbix

cp misc/init.d/tru64/zabbix_agentd /etc/init.d/zabbix_agentd  #将启动程序复制到etc/init.d/

chmod o+x /etc/init.d/zabbix_agentd				#授权，赋予可执行权限

ln -s /usr/local/zabbix/sbin/zabbix_* /usr/local/sbin/ #创建软连接，否则会提示找不到这个执行文件
```

##### 修改zabbix agent 配置文件：

vim /usr/local/zabbix/etc/zabbix_agentd.conf

```
LogFile=/tmp/zabbix_agentd.log
Server=192.168.83.130			#zabbix服务器IP地址

ServerActive=192.168.83.130		#设置为主动模式，主动向zabbix服务器传送数据	

Hostname=192.168.83.131
```

##### 启动zabbix agent 

```
/etc/init.d/zabbix_agentd start
```

##### 修改zabbix server配置文件

```
JavaGateway=192.168.83.131 	#指定java gateway的地址

JavaGatewayPort=10052 		#指定java gateway的服务器监听端口， 如果是默认端口可以不写

StartJavaPollers=5 			#启动多少个进程去轮训 java gateway， 要和java gateway的配置一致

Timeout=30					#如果时间太短，有些数据会获取不到，因为java处理比较慢
```

### 在zabbix web端添加主机

![image-20200509182303208](https://note.youdao.com/yws/api/personal/file/2B24BC522A7B4BBE9B8A0D268F79C60F?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20200509182417338](https://note.youdao.com/yws/api/personal/file/09DC8653789C46248074C2C76CEA5624?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20200509182445424](https://note.youdao.com/yws/api/personal/file/B7E82219B0714D39931C5C97E85A1D12?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20200509182718304](https://note.youdao.com/yws/api/personal/file/94519E2B15A64EBBAE095DC2D636EECE?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

到此监控Tomcat就完成了

参考：https://blog.csdn.net/L835311324/article/details/82988184?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromBaidu-5&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromBaidu-5