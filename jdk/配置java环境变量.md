# 配置java环境变量

#### Linux系统配置：

```
在/etc/profile文件中添加如下内容：
export JAVA_HOME=/usr/local/jdk/  （这里改jdk的路径）
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin

配置完之后输入命令：source  /etc/profile  重新加载一下让环境变量生效
```

#### Windows系统配置：

```
装好jdk之后配置如下：

右击“计算机”，右键打开“属性”，选择“高级系统设置”里面的“环境变量”。在新打开的界面中系统变量需要设置三个属性。

配置用户变量:

a.新建 JAVA_HOME
　　　　　　　　　　   D:\Program Files\Java\jdk1.6.0_10（JDK的安装路径）
b.新建 PATH
　　　　　　　　　　  %JAVA_HOME%\bin;%JAVA_HOME%\jre\bin
c.新建 CLASSPATH
　　　                 .;%JAVA_HOME%\lib;%JAVA_HOME%\lib\tools.jar
```

