# pipeline流水线

​    Pipeline 简而言之，就是一套运行于Jenkins上的工作流框架，将原本独立运行于单个或者多个节点的任务连接起来，实现单个任务难以完成的复杂流程编排与可视化。

声明式：遵循与Groovy相同语法。开头是以pipeline { }

脚本式：支持Groovy大部分功能，也是非常表达和灵活的工具。开头是以node { }

### 参数化构建：

点击流水线语法后看到下图：

![1585487284193](https://note.youdao.com/yws/api/personal/file/CC1559316A4F4D94A9974B204C333623?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)



#### 声明式示例：

```
pipeline {
   agent any
    parameters {	//注意，这里要与agent any 同级，多条参数可以写在一个parameters换行即可；
       choice choices: ['192.168.83.136:9999root/a.git', '192.168.83.136:9999/root/b.git', '192.168.83.136:9999/root/c.git'], description: '请选择要发布的项目git地址', name: 'git'
    
   choice choices: ['192.168.83.130', '192.168.83.131', '192.168.83.132'], description: '请选择要发布的项目主机', name: 'host'
    }
    
   stages {
      stage('1拉取代码') {
         steps {
            echo '步骤测试1'
         }
      }
      stage('2代码构建'){
	     steps {
		   echo '步骤测试2'
		 }
	    }
      stage('3推送代码'){
	     steps {
		   echo '测试步骤3'
		  } 
	    }  
      }
   }
```

效果如下：

![1585487739606](https://note.youdao.com/yws/api/personal/file/5D173FD0CFF04A40AFD0E1D933EF2272?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

脚本式：

```
node{
    stage('code pull'){				#stage是步骤括号里面的是步骤名称，大括号里面的是执行语法；
      echo 'hello,world,code pull'		#这里的echo是Groovy语言的语法命令
      svn 'svn://139.224.227.121:8801/edu/www'	#可以让pipeline自动生成拉取代码的脚本贴到这里
    }
	stage('code build'){
	 echo 'code Build'
	 sh 'mvn clean compile'
	}	
 	stage('unit test'){
 	 echo 'unit test'
 	}
	stage('询问是否部署'){
		input '部署测试环境'		#input实现了询问的功能
	}
	stage('deploy test env'){
	   echo 'deploy test env successfully'
	}
	stage('backup_file to data_bak directory')
		sh '/root/backup_file.sh'
}
#如果需要执行命令可以使用sh的方式来执行
#git或者svn等都可以使用语法生成器来生成
#试下脚本的话可以使用sh来执行
#需要询问可以使用input
#更多语法可以查看pipeline的语法生成器
```

1、jenkins配置gitlab，系统管理----系统设置

2、在gitlab上生成api token 给第一步

3、jenkins 增加构建触发器，勾选上gitlab，同时生成一个token

4、gitlab上创建webhook,填写job的URL和token

----------

### 添加slave节点配置

在jenkins首页--->Manage Jenkins---->Manage Nodes--->New Node

![1585494011786](https://note.youdao.com/yws/api/personal/file/4CAD60A623364501AF3310B62B4035AC?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

注意：slave节点必须要安装jdk，查找java的路径是：/usr/local/java/bin/java所以jdk部署路径是：/usr/local/java  否则会启动失败

![1585493009468](https://note.youdao.com/yws/api/personal/file/5C0100360C4B43999131BC8119EE6860?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

---------------------------

-------------

### pipeline脚本文件构建

pipeline脚本构建，需要先把脚本通过git的方式push到git仓库

具体操作：这里存放jenkins脚本的仓库是: jenkinsfile

在客户端操作：git clone git@192.168.83.135:/home/git/repos/jenkinsfile

cd jenkins

创建项目目录：mkdir  item-a			#项目名称可以自定义

创建一个pipeline脚本文件：touch  item-a/jenkinsfile 然后把脚本内容写入文件    #脚本名称可以自定义

脚本内容：

```
node ("slave-136") {

   stage('git checkout') {
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], u
serRemoteConfigs: [[url: 'git@192.168.83.135:/home/git/repos/app.git']]])
   }
   stage('maven build') {
        echo 'maven clean install'
   }
   stage('deploy') {
       echo 'tomcat'

   }
   stage('test') {
       echo  "curl http://test.aliangedu.com/status.html"
       echo  "hello,xiaofeige verygood"
   }
}
#("slave-136")  #指定某一台slave上执行，slave-136是slave的标签
```

上传到本地代码仓库：

```
步骤如下：
1、	git add .	#添加到本地代码仓库
2、 	git commit -m "jenkinsfile"		#提交并且写描述“jenkinsfile”
3、	git push origin master			#合并到远程git仓库
#注意：每次提交代码都要执行这三部
```

![1586178698176](https://note.youdao.com/yws/api/personal/file/A426AED8BEA54875A95FC0452CF2F868?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

此方式便捷，只要维护这个jenkinsfile脚本即可，无需到jenkins工程中做改动

-----------

### 邮件通知配置

安装邮件插件：Email Extension Plugin

配置发件服务器：

Manage Jenkins--->configure system找到如下：

![1586180685552](https://note.youdao.com/yws/api/personal/file/1F1C3224F901453F8038B25CFF05493A?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586180801868](https://note.youdao.com/yws/api/personal/file/5A97BCFDC519478EB67CE197FD382B10?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

配置到job中

![1586181733078](https://note.youdao.com/yws/api/personal/file/0D601BD260DD4E77BAC850B70CAFAC00?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586181949645](https://note.youdao.com/yws/api/personal/file/DF109425B04F47AF97C3DDBEB9BB3CF9?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586182092967](https://note.youdao.com/yws/api/personal/file/1E9466355ABD4BA58CD62E778F3AB8CC?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586178544152](https://note.youdao.com/yws/api/personal/file/2A97A3F887544D4989B118396D40397A?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

