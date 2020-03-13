#                       dockerfile镜像制作

##### dockerfile的语法命令描述：

```
指令                                   描述

FROM  						构建新镜像是基于哪个镜像 

MAINTAINER   				镜像维护者姓名或邮箱地址 

RUN                       	构建镜像时运行的Shell命令

COPY                      	拷贝文件或目录到镜像中

ENV                        	设置环境变量

USER                       	为RUN、CMD和ENTRYPOINT执行命令指定运行用户

EXPOSE                  	声明容器运行的服务端口

HEALTHCHECK       			容器中服务健康检查

WORKDIR               		为RUN、CMD、ENTRYPOINT、COPY和ADD设置工作目录

ENTRYPOINT          		运行容器时执行，如果有多个ENTRYPOINT指令，最后一个生效 

CMD                       	运行容器时执行，如果有多个CMD指令，最后一个生效
```

##### 下面以tomcat为例：

```
FROM centos:7				#基于哪个镜像构建
MAINTAINER xiaofeige  		#维护者信息

ENV VERSION=8.0.46			#变量：这里写的是tomcat的版本；

RUN yum install java-1.8.0-openjdk wget curl unzip iproute net-tools -y && \
    yum clean all && \
    rm -rf /var/cache/yum/*
#RUN  构建镜像时运行的Shell命令；
RUN wget https://archive.apache.org/dist/tomcat/tomcat-8/v${VERSION}/bin/apache-tomcat-${VERSION}.tar.gz && \
    tar zxf apache-tomcat-${VERSION}.tar.gz && \
    mv apache-tomcat-${VERSION} /usr/local/tomcat && \
    rm -rf apache-tomcat-${VERSION}.tar.gz /usr/local/tomcat/webapps/* && \
    mkdir /usr/local/tomcat/webapps/test && \
    echo "hello,tomcat" > /usr/local/tomcat/webapps/test/status.html && \
    sed -i '1a JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom"'      /usr/local/tomcat/bin/catalina.sh && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime		#修改时区

ENV PATH $PATH:/usr/local/tomcat/bin		#设置tomcat环境变量

WORKDIR /usr/local/tomcat					#设置tomcat的工作目录

EXPOSE 8080									#暴露tomcat端口
CMD ["catalina.sh", "run"]					#运行启动tomcat
```

执行构建： docker build -t tomcat-demo:v1 -f tomcat . 

##### 构建完成之后测试：

 docker run -itd -p 8080:8080  5c1c6a3347d5

##### 查看启动日志：

 docker logs a767e065f1be -f		# -f 参数，实时输出日志；

启动完成之后用浏览器访问：http://192.168.83.128:8080/test/status.html

打开页面看到：hello,tomcat  表示成功；

-------------------

### 将刚刚制作的tomcat-demo镜像push到Harbor镜像仓库：

#### 1、设置镜像标签：

docker  tag tomcat-demo:v1  192.168.83.129/library/tomcat-demo:v1

#### 2、登录Harbor仓库：

docker  login  192.168.83.129

输入账号密码登录后即可push镜像到仓库

注意：docker login 默认是以https加密协议登录的，如果是http协议的话需要做如下修改：

vim  /etc/docker/daemon.json

```
{"registry-mirrors": ["http://f1361db2.m.daocloud.io"],
 "insecure-registries":["192.168.83.129"]
}
```

将上面的代码粘贴到daemon.jason文件中即可，如果没有daemon.json文件就新建，然后重启docker服务；

#### 3、上传镜像到Harbor仓库

docker push 192.168.83.129/library/tomcat-demo:v1

```
[root@localhost dockerfile]# docker push 192.168.83.129/library/tomcat-demo:v1
The push refers to repository [192.168.83.129/library/tomcat-demo]
e066cc945b06: Pushed 
7dd1a1d34aa8: Pushed 
77b174a6a187: Pushed 
v1: digest: sha256:c23221048276dfbdf31cf026e868f172f6fb7285651a1c654c3b39171f939377 size: 952
```


看大上面信息表示push成功；
