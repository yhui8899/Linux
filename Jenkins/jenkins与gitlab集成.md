# jenkins与gitlab集成

jenkins安装gitlab插件

在插件管理----->可选插件----->搜索gitlab------>直接安装即可

配置jenkins连接gitlab

Manager jenkins ------>Configure System----->gitlab

![1586850954855](https://note.youdao.com/yws/api/personal/file/E38619B67F3E45319A3689ED90A8F0C7?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)







gitlab中生成秘钥认证

![1586851023971](https://note.youdao.com/yws/api/personal/file/0197938A3F1C47E88904CB3CC5703400?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586851261062](https://note.youdao.com/yws/api/personal/file/7410CFB1598645559B7617D6E32486A6?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586851339168](assets/1586851339168.png)

在jenkins中配置gitlab的秘钥认证

![1586851567311](https://note.youdao.com/yws/api/personal/file/901F476B653E4229900450A8DBE271F9?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586851748310](https://note.youdao.com/yws/api/personal/file/94A14A7195D545F89C5887833D198F65?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

应用之后保存即可，现在jenkins就可以访问gitlab了

进入到项目工程

![1586853315420](https://note.youdao.com/yws/api/personal/file/4114877010E3486CBE521B3A5BEADB0B?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

这个token主要用来添加web后台用的，在gitlab上配置的，如果收到posh请求就会去调项目JOB的这个URL：http://192.168.83.128:8080/project/pipeline-java 同时带上token

在gitlab中配置jenkins的token

![1586853831452](https://note.youdao.com/yws/api/personal/file/0819B4A9DCC543448F0BFC8E35C7D9D9?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![1586854105056](https://note.youdao.com/yws/api/personal/file/321181757F83427D8BB0F8524BDEB8A8?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

最后点击Add webhook即可

保存时提示报错：[Url is blocked: Requests to the local network are not allowed]

解决方法如下：进入 Admin area => Settings => Network ，然后点击 Outbound requests 右边 的“expand”按钮，如下：

![image-20200513224636218](https://note.youdao.com/yws/api/personal/file/E9B573AE21BD43069417684395756BDE?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

测试是否成功：

在配置Jenkins-token处拉下来可以看到下图点击进行测试即可：

![image-20200513224908142](https://note.youdao.com/yws/api/personal/file/8984A46E914E4E7D84CC32A88BD31996?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)



![image-20200513225007293](https://note.youdao.com/yws/api/personal/file/D0059AE975F3466395B36E24BE8D8595?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

-------------

### 步骤总结：

1、jenkins配置gitlab

2、gitlab生成api token给第一步使用

3、jenkins增加构建触发器，勾选gitlab，同时生成一个token

4、gitlab上创建webhook填写job的URL和token （在gitlab的项目中添加）

5、

