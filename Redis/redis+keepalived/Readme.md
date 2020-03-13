脚本实现功能简介

1, 系统内核设置，添加
```
net.core.somaxconn = 10240
vm.overcommit_memory = 1
```

2. redis 安装
```
#wget -q -O /usr/local/src/redis-3.2.12.tar.gz http://download.redis.io/releases/redis-3.2.12.tar.gz
#tar zxf /usr/local/src/redis-3.2.12.tar.gz -C /usr/local/
#cd /usr/local/redis-3.2.12
#make && make install
#make -p /etc/redis/data
#\cp -pa redis_*.conf /etc/redis/

```

3. redis 配置文件
3.1 redis_master.conf
2台机器配置一样

3.2 redis_salve.conf
注意修改master ip地址
slaveof 192.168.50.92 6379

4. 启动脚本,判断主从关系
4.1 redis_6379 同一启动脚本，修改对应自己的ip
LOCALIP=192.168.50.91
REMOTEIP=192.168.50.92

5, 安装keepalived，不要修改目录下tpl文件
yum install keepalived -y
systemctl enable keepalived.service
更改配置文件中涉及修改部分 

router_id #定义路由标识信息，相同局域网唯一
监控脚本对应路径
state 角色
interface #虚IP地址放置的网卡位置
virtual_router_id  #同一家族要一直，同一个集群id一致
priority    # 优先级决定是主还是备    越大越优先

6, 修改日志文件输出路径

7，修改监控文件

==============================
使用./install.sh 进行安装，先在master服务器上执行安装脚本，后在slave服务器上执行
如果连接不上download.redis.io,可以自己下载redis存放到本地仓库
脚本只进行安装， 不做服务启动
安装后，
redis启动, 会自动判断主从
/etc/init.d/redis_6379
日志
/var/log/redis.log
/var/log/redis-state.log

keepalived启动, 根据install.sh 选择master和backup
systemctl restart keepalived.service
/var/log/keepalived.log

