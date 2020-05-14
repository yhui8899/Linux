# Jenkins集成sonar代码质量检测

安装SonarQube Scanner for Jenkins插件：

主界面--->设置---->插件管理---->可选插件---->右边搜索SonarQube----选择安装即可

![image-20200514172444386](https://note.youdao.com/yws/api/personal/file/0ABE2A56805E4E9AA8D7F1843819529F?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

配置SonarQube

主界面--->设置--->系统设置--->找到：SonarQube servers---->点击Add SonarQube

![image-20200514172953118](https://note.youdao.com/yws/api/personal/file/30074B23A370481EB60063113042E56C?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

配置验证信息：

![image-20200514173305285](https://note.youdao.com/yws/api/personal/file/B8FE6F382E364AA6AAFD09C3AC2E69F4?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

-------------------

配置sonar客户端工具

主界面--->设置--->全局工具配置--->SonarQube Scanner--->点击新增

![image-20200514173934444](https://note.youdao.com/yws/api/personal/file/604FA59E038243818700870FE860B553?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

注意：要在Jenkins服务器中装了Sonar Scanner才行

-------------------

配置job：

![image-20200514174458597](https://note.youdao.com/yws/api/personal/file/3ED5D93CF7C24FC4AEBB707881CAF44D?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20200514182935657](https://note.youdao.com/yws/api/personal/file/E0F573AFC7214B0CB533259A1C4E73C5?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

```
sonar.projectName=${JOB_NAME}	#引用JOB工程的名称

sonar.projectKey=java		    #项目的唯一表示，不能重复

sonar.sources=.					#扫描哪个项目的源码

sonar.java.binaries=.			#项目编译目录
```

到此就配置完成了

![image-20200514175411548](https://note.youdao.com/yws/api/personal/file/332935EDB7C44D1E9245A84BD477CA6F?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20200514184606180](https://note.youdao.com/yws/api/personal/file/83BE7565607B4E989A4A3112F2101FC4?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

到此Jenkins集成sonar就完成了