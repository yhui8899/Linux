# sonarqube 代码质量检测工具部署

##### 官方下载sonarqube：

```
https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-7.0.zip
```
安装程序已上传到百度网盘地址如下：
```
链接：https://pan.baidu.com/s/1HhpZ-j9bbR86KPuxpZXHsg 密码：xxtx
```

##### 解压部署：

```
unzip sonarqube-7.0.zip -d /usr/local/

ln -s /usr/local/sonarqube-7.0 /usr/local/sonarqube
```

##### 创建用户：

```
useradd sonar 
chown -R sonar.sonar /usr/local/sonarqube-7.0
chown -R sonar.sonar /usr/local/sonarqube
```

##### 进入到ssonarqube-8.3/conf目录，打开sonar.properties，作如下配置：

要求mysql版本在5.6以上，sonarqube-7.9之后的版本不支持MySQL数据库

```
sonar.jdbc.username=root
sonar.jdbc.password=qazQAZ
sonar.jdbc.url=jdbc:mysql://192.168.83.105:3306/sonar?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance
&useSSL=false
```

#注意mysql要授权这台主机访问

#注意mysql要授权这台主机访问

##### 修改内核参数：

vim /etc/sysctl.conf 

```
vm.max_map_count=655360
```

vim  /etc/security/limits.conf
```
* soft nofile 65536

* hard nofile 65536
```


通常都是这几个参数的问题导致ES起不来，可以查看相关日志进行排错，日志文件在sonarqube目录下的logs目录

##### 启动sonar服务

```
su - sonar -c "/usr/local/sonarqube/bin/linux-x86-64/sonar.sh start"
```

##### 查看端口：

```
[root@localhost sonarqube]# netstat -tnlp|grep -E "32000|9001|9000|2721"
tcp        0      0 127.0.0.1:32000         0.0.0.0:*               LISTEN      11259/java          
tcp6       0      0 :::9000                 :::*                    LISTEN      11349/java          
tcp6       0      0 127.0.0.1:9001          :::*                    LISTEN      11279/java          
tcp6       0      0 127.0.0.1:2721          :::*                    LISTEN      11516/java     
```

​     

通过浏览器访问：http://192.168.83.132:9000
默认账号密码：admin

##### 汉化包下载：

```
https://github.com/SonarQubeCommunity/sonar-l10n-zh/releases/download/sonar-l10n-zh-plugin-1.16/sonar-l10n-zh-plugin-1.16.jar
```

把下载的汉化包放到：/usr/local/sonarqube/extensions/plugins

```
授权：chown -R sonar.sonar /usr/local/sonarqube/extensions/plugins
```

##### 重启sonar：

```
su - sonar -c "/usr/local/sonarqube/bin/linux-x86-64/sonar.sh restart"
```

通过浏览器访问：http://192.168.83.132:9000  就是中文的了

通过浏览器访问：http://192.168.83.132:9000  就是中文的了

##### 到此sonar服务端就安装完成了，由于sonar服务器只提供服务所以无需装客户端
### sonar客户端安装：

##### 下载sonar客户端：

```
https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.3.0.2102-linux.zip
```

##### 解压部署

```
unzip sonar-scanner-cli-4.3.0.2102-linux.zip -d /usr/local/

ln -s /usr/local/sonar-scanner-cli-4.3.0.2102-linux /usr/local/sonar-scanner
```

##### 修改sonar客户端配置文件：

```
cd /usr/local/sonar-scanner/conf

vim sonar-scanner.properties

sonar.host.url=http://192.168.83.132:9000		#sonar服务器的连接地址

sonar.login=55867c1a51901b4009ac0699ddc259f54f86f151		#sonar登录的token，此token在sonar的web端生成，
服务器需要开启认证才生效：web服务端登录--->配置---->权限---->Force user authentication开启即可

sonar.sourceEncoding=UTF-8			#sonar的字符集编码
```

执行扫描命令：(使用sonar客户端工具扫描java项目)
切换到代码目录然后执行如下指令：

```
/usr/local/sonar-scanner/bin/sonar-scanner  \
-Dsonar.projectKey=java \
-Dsonar.sources=. \
-Dsonar.host.url=http://192.168.83.132:9000  \
-Dsonar.java.binaries=.
```

参数注解：

```
1>.-Dsonar.projectKey //step4中的项目名称

2>.-Dsonar.sources      //需要扫描的项目目录位置

3>. Dsonar.host.url    //sonar服务访问的url地址

4>.Dsonar.login          //令牌名称对应的token

5>.Dsonar.java.binaries //项目编译目录，java为例，则为class文件所在的目录
```



---------------------------------------------
java 代码可以直接使用mvn工具来检测：（使用mvn工具来扫描java项目）

```
mvn  sonar:sonar \
   -Dsonar.host.url=http://192.168.83.132:9000 \
   -Dsonar.login=55867c1a51901b4009ac0699ddc259f54f86f151
```

