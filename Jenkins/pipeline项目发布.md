# pipeline项目发布

## 发布一个PHP项目：

##### 发布流程：使用pipeline脚本发布，

### 1、新建一个为流水线的job

![1586249207726](https://note.youdao.com/yws/api/personal/file/D5BB122806EE4D97BB037FB231650CCC?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

### 2、获取git地址及生成pipeline脚本

##### 打开创建的job找到流水线语法：

![1586249295993](https://note.youdao.com/yws/api/personal/file/7F128FA4B60C4D609A686809F70E3F00?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586249601668](https://note.youdao.com/yws/api/personal/file/ABF4DB33FC7341AF9B6A7514FD1F49F5?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

### 3、上传pipeline脚本到git仓库服务器

##### 3.1、准备pipeline脚本

脚本内容：jenkinsfile-php

```
vim jenkinsfile-php
node ("slave-136") {
   stage('git checkout') {
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], u
serRemoteConfigs: [[url: 'git@192.168.83.135:/home/git/repos/wordpress.git']]])
        }
   stage('code copy') {
        sh '''rm -rf ${WORKSPACE}/.git
        mv /usr/local/nginx/html/wordpress /data/backup/wordpress-$(date +"%F_%T")
        cp -rf ${WORKSPACE} /usr/local/nginx/html/wordpress'''
   }
   stage('test') {
       sh "curl http://192.168.83.136/status.html"
   }
}
#脚本中已经指定了slave-136节点来执行这个pipeline任务，与我的web服务器是同一台主机
#pipeline脚本中有三个stage分别是：git checkout、code copy、test

```

##### 3.2、拉取git仓库的jenkinsfile仓库到本地

```
git clone git@192.168.83.135:/home/git/repos/jenkinsfile
cd jenkinsfile
mkdir item-a	#创建一个项目名称，名称自定义，这里为item-a
把pipeline脚本文件copy到item-a目录下
```

##### 3.3、上传pipeline脚本到git服务器

```
git add .
git commit -m "jenkinsfile-php"
git push origin master
```

### 4、在job中配置指定pipeline脚本文件

![1586250385460](https://note.youdao.com/yws/api/personal/file/5BDA51A4CA964CAFB0DC6F6BADBEE8E8?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

### 5、执行构建发布

##### 点击 Build Now构建

![1586250640853](https://note.youdao.com/yws/api/personal/file/FA15475E63EB4C3AA6CF7569ED3744C0?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

可以在控制台输出中查看构建的详细信息，也可以点击流水线的logs查看

到此就部署完成了；

---------

## 发布一个JAVA项目：

使用shareku代码做测试：

```
unzip shareku.zip
cd shareku
```

### 1、在git服务器创建项目

```
cd /home/git/repos/
mkdir shareku.git
git --bare init
```

### 2、提交代码到git仓库

```
进入solo-master目录执行：
git init

git remote add origin git@192.168.83.135:/home/git/repos/shareku.git	#设置一个git地址

git add .

git commit -m "all"

git push origin master		#推送到git仓库
```

### 3、上传pipeline脚本到git仓库服务器

##### 3.1、准备pipeline脚本

脚本内容：

```
node ("slave-135") {
   //def mvnHome = '/usr/local/maven'
   stage('git checkout') {
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], u
serRemoteConfigs: [[url: 'git@192.168.83.135:/home/git/repos/shareku.git']]])
        }
   stage('maven build') {
        sh '''export JAVA_HOME=/usr/local/jdk
        /usr/local/maven/bin/mvn clean package -Dmaven.test.skip=true'''
   }
   stage('deploy') {
        sh '''
        JENKINS_NODE_COOKIE=dontkillme	#由于pipeline任务执行完成后会关闭进程所以tomcat的进程也会被kill掉，所以需要加这条参数即可解决这个问题
        export JAVA_HOME=/usr/local/jdk
        TOMCAT_NAME=tomcat
        TOMCAT_HOME=/usr/local/$TOMCAT_NAME
        WWWROOT=$TOMCAT_HOME/webapps/ROOT

        if [ -d $WWWROOT ]; then
           mv $WWWROOT /data/backup/${TOMCAT_NAME}-$(date +"%F_%T")
        fi
        unzip ${WORKSPACE}/target/*.war -d $WWWROOT
        PID=$(ps -ef |grep $TOMCAT_NAME |egrep -v "grep|$$" |awk \'{print $2}\')
        [ -n "$PID" ] && kill -9 $PID  
			#[ -n "$PID" ] 如果$PID不为空就执行后面的kill -9 $PID 杀掉进程
        /bin/bash $TOMCAT_HOME/bin/startup.sh'''
   }
   stage('test') {
       sh "sleep 30 && curl http://192.168.83.135:8080"
   }
}

#脚本中已经指定了slave-135节点来执行这个pipeline任务，与我的web服务器是同一台主机
```

##### 3.2、拉取git仓库的jenkinsfile仓库到本地

```
git clone git@192.168.83.135:/home/git/repos/jenkinsfile
cd jenkinsfile
mkdir item-java	#创建一个项目名称，名称自定义，这里为item-java
把pipeline脚本文件copy到item-java目录下
```

##### 3.3、上传pipeline脚本到git服务器

```
git add .
git commit -m "jenkinsfile-php"
git push origin master
```

### 4、在job中配置指定pipeline脚本文件

![1586259052239](https://note.youdao.com/yws/api/personal/file/78D4CF3856E3451B96E8AF2D6A0BB973?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

### 5、执行构建发布

点击 Build with Parameterized

![1586269944771](https://note.youdao.com/yws/api/personal/file/3587C39A9E7A4DB99384DB06B0C72E4B?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

java项目发布就到此完成了

-------------

### 项目发布到docker：

创建一个pipeline项目

定义一个参数化构建：以 tag版本的的方式来构建

![1586849309690](https://note.youdao.com/yws/api/personal/file/7300BFBD3A1648B299E49E942875645E?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

获取git地址转换为pipeline脚本：

将如下代码写到pipeline脚本的git checkout的stage中

```
checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'git@192.168.83.135:/home/git/repos/sharek.git']]])
```

脚本内容如下：

```
node ("slave-136") {
	stage('git checkout'){
		checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'git@192.168.83.135:/home/git/repos/sharek.git']]])
	}
	stage ('Manven Build'){
		sh '''
		export JAVA_HOME=/usr/local/java
		/usr/local/maven/bin/mvn clean package -Dmaven.test.skip=true
		'''
	}
	stage ('Build and Push Image'){
sh ''' 
REPOSITORY=192.168.83.144/docker-java/shareku:${tag}
cat >Dockerfile << EOF
FROM 192.168.83.144/docker-java/tomcat:v1
RUN  rm -rf /usr/local/tomcat/webapps/ROOT
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war
CMD ["catalina.sh","run"]
EOF
docker build -t ${REPOSITORY} -f Dockerfile .
docker login -u xiaofeige -p Yhui8899 192.168.83.144
docker push ${REPOSITORY}
'''
	}
	stage ('Deploy to Docker'){
		sh '''
		REPOSITORY=192.168.83.144/docker-java/shareku:${tag}
		docker rm -f shareku |true
		docker image rm ${REPOSITORY} |true
		docker login -u xiaofeige -p Yhui8899 192.168.83.144
		docker container run -d --name shareku -v /usr/local/jdk:/usr/local/jdk -p 88:8080 ${REPOSITORY}
		'''
	}
}
```

![1586849408335](https://note.youdao.com/yws/api/personal/file/A9D6083086884B4084E0F0916618F8C4?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

然后构建即可

![1586849422846](https://note.youdao.com/yws/api/personal/file/8439E17C89734D3E8D5D4F5F903307A2?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)