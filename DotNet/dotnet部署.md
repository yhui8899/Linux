# 							dotnet部署：

先检查主机是否有安装dotnet：rpm -qa|grep dotnet ,如有安装可以删除：rpm -qa|grep dotnet|xargs rpm -e

1. #### 创建dotnet目录：

   ```
   mkdir  /dotnet
   
   cd  /dotnet
   ```

   

2. #### 下载 linux版本的tar包

   ```
   https://download.visualstudio.microsoft.com/download/pr/5e92f45b-384e-41b9-bf8d-c949684e20a1/67a98aa2a4e441245d6afe194bd79b9b/dotnet-sdk-2.2.300-linux-x64.tar.gz
   
   tar -xf  dotnet-sdk-2.2.300-linux-x64.tar.gz
   ```

   

3. #### 配置环境变量：

   ```
   echo  ‘export PATH=$PATH:/dotnet/’ >>/etc/profile
   
   source /etc/profile
   ```

   

4. #### 使用测试命令

   dotnet --version   #查看版本：

   ```
   [root@localhost ~]# dotnet --version
   2.2.300
   ```

   

------------

# 创建并编译

#### 创建MVC工程：

使用如下指令创建ASP.NET Core2.1的工程：

```
dotnet new MVC -o MvcDemoApp
```

#### 修改代码：

默认的情况下ASP.NET Core2.1本地启动会运行在 Kestrel服务器上，如果想要从其他电脑访问网站，则需要修改绑定。

打开新建的工程文件中的 Program.cs 文件，修改代码如下：

```
         public static IWebHostBuilder CreateWebHostBuilder(string[] args) =>
             WebHost.CreateDefaultBuilder(args)
                 .UseUrls("https://0.0.0.0:5001")
                 .UseStartup<Startup>();
```

这样绑定的便是服务器上的所有IP，而不只是默认的 localhost。



#### 编译程序

##### 在终端运行如下指令：

```
dotnet publish --configuration Release
```

该指令所有的文件放到 /bin/Release/netcoreapp2.1/publish文件夹中。为了方便管理，我们将该目录下的文件放到Linux服务器下的 /data/RunService/MvcDemo 路径下。

```
mkdir -p  /data/RunService/MvcDemo 

\cp -pa /bin/Release/netcoreapp2.1/publish/*  /data/RunService/MvcDemo 
```

完成了.NET Core程序的创建和编译后，现在开始程序的部署。

最简单的是直接进入程序的根目录 /home/RunService/MvcDemo ，然后执行指令：

dotnet MvcDemoApp.dll		

提示如下表示成功：

```
[root@localhost MvcDemo]# dotnet MvcDemoApp.dll
warn: Microsoft.AspNetCore.DataProtection.KeyManagement.XmlKeyManager[35]
      No XML encryptor configured. Key {61b83ea1-693f-47a8-bc76-4a5b9ac6f537} may be persisted to storage in unencrypted form.
Hosting environment: Production
Content root path: /home/RunService/MvcDemo
Now listening on: https://0.0.0.0:5001
Application started. Press Ctrl+C to shut down.
```

##### 为了更方便管理，我们来配置一下将网站当做服务来运行

vim  /etc/systemd/system/MvcDemo_Conf.service

```
[Unit]
Description=.NET Core Test App

[Service]
WorkingDirectory=/data/RunService/MvcDemo	#根据实际情况修改
ExecStart=/dotnet/dotnet /data/RunService/MvcDemo/MvcDemoApp.dll  #根据实际情况修改
Restart=always		#重启策略
RestartSec=10
SyslogIdentifier=MvcDemoApp
User=root			#使用root用户来启动
Environment=ASPNETCORE_ENVIRONMENT=Production

[Install]
WantedBy=multi-user.target
```

##### 执行如下命令：

```
systemctl daemon-reload				#加载服务配置

systemctl start MvcDemo_Conf.service		#启动MvcDemo_Conf.service服务

systemctl status MvcDemo_Conf.service 	    #查看MvcDemo_Conf.service服务器状态
```

参考：https://www.cnblogs.com/imstrive/p/9674576.html