# jenkins参数化构建

![1586165339996](https://note.youdao.com/yws/api/personal/file/938BAA7DC3694C08965AA59B37F1128E?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

​		#如上图的参数名称可以给当前工程来传参，调用，例如只用shell脚本来调用或者分支名称调用等

####  扩展参数化构建插件：

需安装插件：Extended Choice Parameter与Git Parameter

![1586165991932](https://note.youdao.com/yws/api/personal/file/82A873E4664C40148C47962FBE81E06B?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586166847223](https://note.youdao.com/yws/api/personal/file/AA133AFF1BFE4AEA8564A9A30A7F859F?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

```
单词注解
Description：描述

Basic Parameter Types：基本参数类型

Parameter Type：参数类型

Number of Visible Items：可见项目数

Delimiter：	分割符
```

![1586167012004](https://note.youdao.com/yws/api/personal/file/C22BF01F13294C8B90FB75D13A43607F?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

上面我们测试了value，接下来测试Property File读取key值

![1586168208050](https://note.youdao.com/yws/api/personal/file/2EFCD02BD6834B818635FA39F283E983?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586168285298](https://note.youdao.com/yws/api/personal/file/B9F1F589BE6946CC807625529A6A9BA3?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

#### Git Parameter插件：

git参数提供了一个主要的功能：可以直接获取当前git项目的分支号、tag或版本等

由于jenkins默认使用jenkins的用户去连接git地址，需要先切换jenkins用户然后做免密钥，由于我的jenkins安装的时候没有创建家目录，所以这里使用root用户来连接git服务器，修改配置文件如下：

```
vim /etc/sysconfig/jenkins
JENKINS_USER="root"	
#默认是：JENKINS_USER="jenkins"
```

Git Parameter配置如下：

![1586170510992](https://note.youdao.com/yws/api/personal/file/83592F34FB7841849CDE5800CF137B42?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

配置链接Git的地址：

![1586171149328](https://note.youdao.com/yws/api/personal/file/80B41DD51BB042D29DFDD050D63FD20B?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586171565278](https://note.youdao.com/yws/api/personal/file/392F299DF9D94226BA9473000273E9BF?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

