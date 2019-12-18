

# docker部署与管理笔记

**docker部署：**

```
安装依赖包：yum install yum-utils device-mapper-persistent-data lvm2 -y 
```

下载docker软件包源：

```
wget -c https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

mv  docker-ce.repo  /etc/yum.repos.d/
```

或者：

```
yum-config-manager --add-repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

```

安装docker-ce

```
yum install docker-ce  -y
```

启动docker服务：

```
systemctl start  docker
```

设置开机启动docker

```
systemctl  enable  docker
```

docker公共镜像仓库地址：https://hub.docker.com/explore     和docker search 是一样的



配置镜像加速器（即国内源）

curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://f1361db2.m.daocloud.io

**到此docker部署完毕；**

-----------------------------------------------------------------------------------------------------------------------------------------------------

**docker常用命令：**

```
docker	image ls		查看docker镜像

docker	build		构建镜像来自于dockerfile

docker	history		查看镜像历史

docker	inspect		显示一个或多个镜像详细信息

docker	pull		从镜像仓库拉取镜像

docker	push		推送一个镜像到镜像仓库

docker	rmi			删除一个或多个镜像

docker	prune		移除为使用的镜像，没有被标记或被任何容器引用的；

docker	tag			创建一个引用源镜像标记目标镜像（可用于改名）

docker	stats		查看容器资源使用情况及状态；

docker	export		导出容器文件系统到tar归档文件，（即容器导出）

docker	import		导入容器文件系统tar归档文件创建镜像	（即导入容器文件为镜像）

docker	save		保存一个或多个镜像到一个tar归档文件；
					如：docker save centos:7 > centos7.tar

docker	load		加载镜像来自tar归档或标准输入；
```



**docker数据存放目录：**

/var/lib/docker

----------------------------------------------------------------------------------------------------------------------------------------------------------



## 容器管理：

**docker  run  启动参数：**

```
选项                                                              描述
docker run 		-i, –interactive              交互式
docker run		-t, –tty                分配一个伪终端
docker run		-d, –detach             运行容器到后台
docker run		-e, –env                设置环境变量
docker run		-p, –publish list       发布容器端口到主机
docker run		-P, –publish-all        发布容器所有EXPOSE的端口到宿主机随机端口
docker run		–name string            指定容器名称
docker run		-h, –hostname           设置容器主机名
docker run		–ip string              指定容器IP，只能用于自定义网络
docker run		–network                连接容器到一个网络
docker run		–mount mount            将文件系统附加到容器
docker run		-v, –volume list        绑定挂载一个卷
docker run		–restart string        容器退出时重启策略，默认no，可选值：[always|on-failure]
docker run		--privileged			赋予此容器扩展的特权 (给容器设置特权)

```

**容器资源管理:**

```
启容器时指定资源限制：
选项                                                  描述
-m，–memory                                	 容器可以使用的最大内存量
		如：docker run -itd -m 1G  nginx:1.15

–memory-swap                               允许交换到磁盘的内存量
–memory-swappiness=<0-100>    	容器使用SWAP分区交换的百分比（0-100，默认为-1）
–oom-kill-disable                            禁用OOM Killer
-–cpus                                        可以使用的CPU数量
		如：docker run -itd -m 1G --cpus 2 nginx:1.15	给容器分配2核CPU
–cpuset-cpus                                 限制容器使用特定的CPU核心，如(0-3, 0,1)
–cpu-shares                                  CPU共享（相对权重）

可查看看help帮助:docker run --help|grep memory
查看容器的状态及资源使用情况，实时输出；
docker stats f908a85f722e
```

**内存限额：**

允许容器最多使用500M内存和100M的Swap，并禁用OOM Killer：

docker run -d --name nginx03 --memory="500m" --memory-swap=“600m" --oom-kill-disable nginx

**CPU限额：**

```
允许容器最多使用一个半的CPU：
docker run -d --name nginx04 --cpus="1.5" nginx

允许容器最多使用50%的CPU：
docker run -d --name nginx05 --cpus=".5" nginx

允许容器最多使用一个半的CPU：
docker run -d --name nginx04 --cpus="1.5" nginx

允许容器最多使用50%的CPU：
docker run -d --name nginx05 --cpus=".5" nginx

容器资源可以动态更新：
docker update -m 2G 454c93b1631c	#更新内存资源
注意：前提是启容器的时候已经分配了资源才可以修改，否则无法更新，会报错；
```

-----------------------------------------------------------------------------------------------------------------------------------------------------------



### docker常用的基本命令：

**选项**                                  **描述**
ls                      列出容器

​						如：docker 	exec 	e29491b8c356  ls		#容器后面执行ls 命令；

inspect             查看一个或多个容器详细信息 exec ，在运行容器中执行命令 commit ，创建一个新镜像来自一个容器

exec				进入容器或在运行容器中执行命令；

​						如：docker exec   e29491b8c356   ls

​						如：docker exec   e29491b8c356   pwd

cp                     拷贝文件/文件夹到一个容器

​						如：docker  cp /root/index.html  e29491b8c356:/tmp/

logs                  获取一个容器日志；

​						如：docker logs f908a85f722e -f 		# -f	实时查看容器日志；						

port                  列出或指定容器端口映射

​							如：docker port f908a85f722e		如容器有映射端口的话会列出来；

top                   显示一个容器运行的进程

​						如：docker top f908a85f722e		查看容器中运行了那些进程

stats                 显示容器资源使用统计 

​							如：docker stats f908a85f722e  		#交互，实时输出；

​							如：docker stats f908a85f722e --no-stream	#直接输出，不交互；

stop/start         停止/启动一个或多个容器 

​							如：docker  start	 f908a85f722e 

rm   删除一个或多个容器

​							如：docker rm  -f   f908a85f722e 	# -f  强制删除容器；



-----------------------------------------------------------------------------------------------------------------------------------------------------------

## 管理应用程序数据：

1.将数据从宿主机挂载到容器中的三种方式：
2.Volume
3.Bind Mounts

Docker提供三种方式将数据从宿主机挂载到容器中：
•volumes：Docker管理宿主机文件系统的一部分（/var/lib/docker/volumes）。保存数据的最佳方式。
•bind mounts：将宿主机上的任意位置的文件或者目录挂载到容器中。
•tmpfs：挂载存储在主机系统的内存中，而不会写入主机的文件系统。如果不希望将数据持久存储在任何位置，可以使用tmpfs，同时避免写入容器可写层提高性能。

常用的两种方式：volume、Bind Mounts

#### 管理卷：volume

```
管理卷：volume

docker  volume  create  wwwrooot	
		#创建一个wwwroot的数据卷，该数据保存在：/var/lib/docker/volumes/wwwroot/

docker volume  ls					#查看数据卷

docker volume inspect wwwroot		#查看数据卷的详细信息；

注意：
1.如果没有指定卷，自动创建。
	如：docker run -d --name=nginx-1.15 --mount src=wwwroot2,dst=/usr/share/nginx/html nginx:1.15，没有创建wwwroot2，启动时会启动创建wwwroot2数据卷；
	
2.建议使用--mount，更通用。
```

**用卷创建一个容器：**

```
docker run -d --mount src=wwwroot,dst=/usr/share/nginx/html nginx:1.15

或:	

docker run -itd --name=nginx-test -v wwwroot:/usr/share/nginx/html nginx:1.15

docker inspect nginx-1.15|grep -C 3 _data	#查看磁盘卷挂载状态

docker ps -l  	#查看最近创建的一个容器
```



**清理删除容器：**

```
docker stop nginx-1.15		#停止容器

docker rm nginx-1.15		#删除容器	

docker volume rm wwwroot	#删除数据卷


```

磁盘卷的官网文档地址：https://docs.docker.com/engine/admin/volumes/volumes/#start-a-container-with-a-volume

#### 管理卷：Bind Mounts

docker run -itd --name=nginx-bin_mounts --mount type=bind,src=/data,dst=/usr/share/nginx/html nginx:1.15 

或

docker run -itd --name=nginx-test -v /data:/usr/share/nginx/html nginx

注意：
1.如果源文件/目录没有存在，不会自动创建，会抛出一个错误。
2.如果挂载目标在容器中非空目录，则该目录现有内容将被隐藏。



##### **volume和Bind Mounts特点**

**Volume特点：**
•多个运行容器之间共享数据，当容器停止或被移除时，该卷依然存在。
•多个容器可以同时挂载相同的卷。
•当明确删除卷时，卷才会被删除。
•将容器的数据存储在远程主机或其他存储上
•将数据从一台Docker主机迁移到另一台时，先停止容器，然后备份卷的目录（/var/lib/docker/volumes/）



**Bind Mounts特点：**
	•从主机共享配置文件到容器。默认情况下，挂载主机/etc/resolv.conf到每个容器，提供DNS解析。
	•在Docker主机上的开发环境和容器之间共享源代码。例如，可以将Maven target目录挂载到容器中，每次在		Docker主机上构建Maven项目时，容器都可以访问构建的项目包。
	•当Docker主机的文件或目录结构保证与容器所需的绑定挂载一致时。

​		（bind mounts 针对配置文件等其他数据文件更适用）

如：docker run -itd --name=centos-bind --mount type=bind,src=/etc/resolv.conf,dst=/etc/resolv.conf centos:7  将/etc/resolv.conf文件挂载到容器的/etc/resolv.conf （容器的文件会隐藏）



## 容器网络：

1.网络模式
2.容器网络访问原理

容器网络一共有以下五种网络模式：

**bridge**

–net=bridge默认网络，Docker启动后创建一个docker0网桥，默认创建的容器也是添加到这个网桥中。

**host**

–net=host容器不会获得一个独立的network namespace，而是与宿主机共用一个。这就意味着容器不会有自己的网卡信息，而是使用宿主机的。容器除了网络，其他都是隔离的。

**none**

–net=none获取独立的network namespace，但不为容器进行任何网络配置，需要我们手动配置。

**container**

–net=container:Name/ID与指定的容器使用同一个network namespace，具有同样的网络配置信息，两个容器除了网络，其他都还是隔离的。

**自定义网络**

与默认的bridge原理一样，但自定义网络具备内部DNS发现，可以通过容器名或者主机名容器之间网络通信。



可使用调试容器来做测试：

​	docker run -it busybox		#busybox 调试使用的容器



**自定义网络：**

​	docker network ls	查看网络名

​	docker network create net-test		创建一个网络名

​	docker network rm net-test			删除一个网络名

​	docker network inspect net-test 		查看网络名的详细信息

```
测试自定义网络：**

docker run -it --name=bs1 --net net-test 19485c79a9bb

docker run -it --name=bs2 --net net-test 19485c79a9bb

docker run -it --name=bs3 --net net-test 19485c79a9bb

docker run -it --name=bs4 --net net-test 19485c79a9bb

如上所示即可使用容器名进行通信；

进入到容器：
/ # ping bs2
PING bs2 (172.18.0.2): 56 data bytes
64 bytes from 172.18.0.2: seq=0 ttl=64 time=0.248 ms
64 bytes from 172.18.0.2: seq=1 ttl=64 time=0.057 ms
64 bytes from 172.18.0.2: seq=2 ttl=64 time=0.058 ms
```









