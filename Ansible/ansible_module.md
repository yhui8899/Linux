# 													ansible常用模块

关于模块的使用方法，需要注意的是"state"。很多模块都会有该选项，且其值几乎都包含有"present"和"absent"，表示肯定和否定的意思。

present：安装

absent：  移除

---------------------------------------------

### ansible常用的模块：

ansible 模块查询：ansibel-doc -s script|more

#### command模块：

```
用法：ansible web -m command -a ’ifconfig‘

	ansible web -m command -a 'ls /root/test.sh'
```



#### shell模块：

```
用法：ansible web -m shell -a  'df -hT'
#直接执行shell命令
```



#### copy模块：

```
用法：ansible web -m copy -a 'src=/root/test.sh dest=/root/test.sh'

其相关选项如下：

src　  #被复制到远程主机的本地文件。可以是绝对路径，也可以是相对路径。如果路径是一个目录，则会递归复制，用法类似于"rsync"

content　　　#用于替换"src"，可以直接指定文件的值
例如：ansible web -m copy -a 'content="hello\nworld!" dest=/root/111.txt mode=644'

dest　　　　#必选项，将源文件复制到的远程主机的绝对路径；

backup　　　#当文件内容发生改变后，在覆盖之前把源文件备份，备份文件包含时间信息

directory_mode　　　　#递归设定目录的权限，默认为系统默认权限

force　　　　#当目标主机包含该文件，但内容不同时，设为"yes"，表示强制覆盖；设为"no"，表示目标主机的目标位置不存在该文件才复制。默认为"yes"

others　　　　#所有的 file 模块中的选项可以在这里使用

```

#### file模块：

```
该模块主要用于设置文件的属性，比如创建文件、创建链接文件、删除文件等。
下面是一些常见的命令：

force　　#需要在两种情况下强制创建软链接，一种是源文件不存在，但之后会建立的情况下；另一种是目标软链接已存在，需要先取消之前的软链，然后创建新的软链，有两个选项：yes|no

group　　#定义文件/目录的属组。后面可以加上mode：定义文件/目录的权限

owner　　#定义文件/目录的属主。后面必须跟上path：定义文件/目录的路径

recurse　　#递归设置文件的属性，只对目录有效，后面跟上src：被链接的源文件路径，只应用于state=link的情况

dest　　#被链接到的路径，只应用于state=link的情况

state　　#状态，有以下选项：

	directory：如果目录不存在，就创建目录

	file：即使文件不存在，也不会被创建

	link：创建软链接

	hard：创建硬链接

	touch：如果文件不存在，则会创建一个新的文件，如果文件或目录已存在，则更新其最后修改时间

	absent：删除目录、文件或者取消链接文件

用法举例如下：
ansible web -m file -a 'path=/data/app state=directory' #在远程主机上创建了data/app目录；

创建软链接：
ansible web -m file -a 'path=/data/bbb.jpg src=aaa.jpg force=yes state=link'
#force=yes   如果文件不存在则会创建
```

#### fetch模块：

```
该模块用于从远程某主机获取（复制）文件到本地。
有两个选项：

dest：用来存放文件的目录

src：在远程拉取的文件，并且必须是一个file，不能是目录
具体举例如下：
ansible web -m fetch -a 'src=/root/111.txt dest=/data/app'

```

#### cron模块：

```
该模块适用于管理cron计划任务的。
其使用的语法跟我们的crontab文件中的语法一致，同时，可以指定以下选项：

day= #日应该运行的工作( 1-31, , /2, )

hour= # 小时 ( 0-23, , /2, )

minute= #分钟( 0-59, , /2, )

month= # 月( 1-12, *, /2, )

weekday= # 周 ( 0-6 for Sunday-Saturday,, )

job= #指明运行的命令是什么

name= #定时任务描述

reboot # 任务在重启时运行，不建议使用，建议使用special_time

special_time #特殊的时间范围，参数：reboot（重启时），annually（每年），monthly（每月），weekly（每周），daily（每天），hourly（每小时）

state #指定状态，present表示添加定时任务，也是默认设置，absent表示删除定时任务

user # 以哪个用户的身份执行

具体举例如下：
① 添加计划任务
ansible web -m cron -a 'name="ntp update every 5 min" minute=*/5 job="/sbin/ntpdate 192.168.83.145 &> /dev/null"'
	
查看刚刚添加的计划任务：
[root@localhost data]# ansible web -m shell -a 'crontab -l'
web3 | CHANGED | rc=0 >>
#Ansible: ntp update every 5 min
*/5 * * * * /sbin/ntpdate 192.168.83.145 &> /dev/null

web2 | CHANGED | rc=0 >>
#Ansible: ntp update every 5 min
*/5 * * * * /sbin/ntpdate 192.168.83.145 &> /dev/null

web1 | CHANGED | rc=0 >>
#Ansible: ntp update every 5 min
*/5 * * * * /sbin/ntpdate 192.168.83.145 &> /dev/null
可以看出，我们的计划任务已经设置成功了。


② 删除计划任务
如果我们的计划任务添加错误，想要删除的话，则执行以下操作：
ansible web -m cron -a 'name="ntp update every 5 min" minute=*/5 job="/sbin/ntpdate 192.168.83.145 &> /dev/null" state=absent'
注解：
name="ntp update every 5 min"  #任务名称
minute=*/5		#执行时间
job="/sbin/ntpdate 192.168.83.145 &> /dev/null"  #执行的命令；
state=absent	#状态，absent即删除；

再来查看一下刚刚创建的任务是否删除成功：
[root@localhost data]# ansible web -m shell -a 'crontab -l'
web3 | CHANGED | rc=0 >>


web2 | CHANGED | rc=0 >>


web1 | CHANGED | rc=0 >>
可以看出，我们的计划任务已经成功删除了；
```



#### yum模块：

```
顾名思义，该模块主要用于软件的安装。
其选项如下：
name=　　#所安装的包的名称

state=　　#present--->安装， latest--->安装最新的, absent---> 卸载软件。

update_cache　　#强制更新yum的缓存

conf_file　　#指定远程yum安装时所依赖的配置文件（安装本地已有的包）。

disable_pgp_check　　#是否禁止GPG checking，只用于presentor latest。

disablerepo　　#临时禁止使用yum库。 只用于安装或更新时。

enablerepo　　#临时使用的yum库。只用于安装或更新时。

下面我们就来安装一个包试试看：
ansible web -m yum -a 'name=htop state=present'		#安装htop软件；
我们来查看一下刚刚安装的htop软件是否成功：
[root@localhost ~]# ansible web -m shell -a 'rpm -qa|grep htop'

web1 | CHANGED | rc=0 >>
htop-2.2.0-3.el7.x86_64

web2 | CHANGED | rc=0 >>
htop-2.2.0-3.el7.x86_64

web3 | CHANGED | rc=0 >>
htop-2.2.0-3.el7.x86_64
可以看到我们刚刚安装的htop已经成功了；

ansible web -m yum -a 'name=nginx state=present'  #安装nginx；
```



#### get_url模块：

```
get_url模块等同于wget ，可用于文件下载；
必要参数：
URL: URL地址；
dest: 目的地址，即文件保存路径；
具体示例：
ansible web -m get_url -a 'url=http://nginx.org/download/nginx-1.17.7.tar.gz dest=/tmp/'
#下载nginx到远程主机的/tmp目录下；
```



#### service模块：

```
该模块用于服务程序的管理。
其主要选项如下：
arguments #命令行提供额外的参数

enabled #设置开机启动。

name= #服务名称

runlevel #开机启动的级别，一般不用指定。

sleep #在重启服务的过程中，是否等待。如在服务关闭以后等待2秒再启动。(定义在剧本中。)

state #有四种状态，分别为：started--->启动服务， stopped--->停止服务， restarted--->重启服务， reloaded--->重载配置　　

1、 开启服务并设置自启动：
ansible web -m service -a 'name=nginx state=started  enabled=true' 
查看自启动是否设置成功：
[root@localhost ~]# ansible web -m shell -a 'systemctl is-enabled nginx'
web2 | CHANGED | rc=0 >>
enabled

web1 | CHANGED | rc=0 >>
enabled

web3 | CHANGED | rc=0 >>
enabled

2、关闭服务：
ansible web -m service -a 'name=nginx state=stopped'
```



#### user模块：

```
该模块主要是用来管理用户账号。
其主要选项如下：

comment　　	# 用户的描述信息

createhome　　# 是否创建家目录

force　　		# 在使用state=absent时, 行为与userdel –force一致.

group　　		# 指定基本组

groups　　	# 指定附加组，如果指定为(groups=)表示删除所有组

home　　		# 指定用户家目录

move_home　　 # 如果设置为home=时, 试图将用户主目录移动到指定的目录

name　　		# 指定用户名

non_unique　　# 该选项允许改变非唯一的用户ID值

password　　	# 指定用户密码

remove　　	# 在使用state=absent时, 行为是与userdel –remove一致

shell　　		# 指定默认shell

state　　		# 设置帐号状态，不指定为创建，指定值为absent表示删除

system　　	# 当创建一个用户，设置这个用户是系统用户。这个设置不能更改现有用户
	
uid　　		# 指定用户的uid

具体举例如下：
1、添加一个用户并指定其 uid
ansible web -m user -a 'name=ansible uid=11111' 
#添加一个用户：ansible 并指定用户ID：11111
ansible web -m user -a 'name=ansible uid=11111 createhome=no'
#添加一个用户：ansible 并指定用户ID：11111，不创建家目录

2、删除用户
ansible web -m user -a 'name=ansible state=absent'

```



#### group模块：

```
该模块主要用于添加或删除组。
常用的选项如下：
gid=　　#设置组的GID号

name=　　#指定组的名称

state=　　#指定组的状态，默认为创建，设置值为absent为删除

system=　　#设置值为yes，表示创建为系统组

具体举例如下：
1、创建组：
ansible web -m group -a 'name=xiaofeige gid=12222'
#创建组：xiaofeige shezhi 组ID：12222
2、删除组：
ansible web -m group -a 'name=xiaofeige state=absent'
```



#### script模块：

```
该模块用于将本机的脚本在被管理端的机器上运行。
该模块直接指定脚本的路径即可，我们通过例子来看一看到底如何使用的：
首先，我们写一个脚本，并给其加上执行权限：
vim /tmp/df.sh
[root@localhost /]# vim /tmp/df.sh 
#!/bin/bash
ifconfig >>/tmp/ifconfig.log
df -hT >>/tmp/ifconfig.log

设置脚本执行权限：
chmod o+x /tmp/df.sh 

然后，我们直接运行命令来实现在被管理端执行该脚本：
ansible web -m script -a '/tmp/df.sh'
加chdir:
ansible web -m script -a 'chdir=/tmp df.sh'

查看有没有把日志写到/tmp/ifconfig.log文件中：
ansible web -m shell -a 'cat /tmp/ifconfig.log'
```



#### synchronize模块：

```
synchronize 基于rsync命令批量同步文件

参数: 做这个模块的时候，必须保证远程服务器上有rsync这个命令：
compress : 压缩传输(默认开启)
archive : 是否采用归档模式同步,保证源文件和目标文件属性一致
checksum : 是否校验
dirs : 非递归传送目录
links : 同步链接指向文件
recursive : 是否递归yes/no
rsync_opts : 使用rsync参数
copy_links : 同步的时候是否复制链接
delete : 以推送方为主的无差异同步传输
src : 源目录以文件
dest : 目标文件及目录
dest_port : 目标接受的端口
rsync_path : 服务的路径,指定rsync在远程服务器上执行
rsync_remote_user : 设置远程用户名
--exclude=*.log : 此处为忽略.log结尾的文件, 必须和rsync_opts使用例(rsync_opts=--exclude=.txt)
mode : 同步模式,rsync的同步模式默认推送(push)从远端拉取为(pull)

具体示例：
ansible all -m synchronize -a 'src=/tmp/test dest=/data/soft/ compress=yes'

```



#### setup模块：

```
该模块主要用于收集信息，是通过调用facts组件来实现的。
　　facts组件是Ansible用于采集被管机器设备信息的一个功能，我们可以使用setup模块查机器的所有facts信息，可以使用filter来查看指定信息。整个facts信息被包装在一个JSON格式的数据结构中，ansible_facts是最上层的值。
　　facts就是变量，内建变量 。每个主机的各种信息，cpu颗数、内存大小等。会存在facts中的某个变量中。调用后返回很多对应主机的信息，在后面的操作中可以根据不同的信息来做不同的操作。如redhat系列用yum安装，而debian系列用apt来安装软件。
　　
1、查看信息：
我们可以直接用命令获取到变量的值，具体我们来看看例子：
ansible web -m setup -a 'filter="*mem*"'	#查看内存
ansible web -m setup -a 'filter="*cpu*"'	#查看CPU

2、保存信息
我们的setup模块还有一个很好用的功能就是可以保存我们所筛选的信息至我们的主机上，同时，文件名为我们被管制的主机的IP，这样方便我们知道是哪台机器出的问题。

ansible web -m setup -a 'filter="*mem*"' --tree /tmp/facts
#将采集到的信息保存在/tmp/facts目录下；
```



#### unarchive模块：

```
这个模块的主要作用就是解压。模块有两种用法：
1：如果参数copy=yes，则把本地的压缩包拷贝到远程主机，然后执行解压缩。
2：如果参数copy=no，则直接解压远程主机上给出的压缩包

1.creates：指定一个文件名，当该文件存在时，则解压指令不执行

2.dest：远程主机上的一个路径，即文件解压的路径 

3.grop：解压后的目录或文件的属组

4.list_files：如果为yes，则会列出压缩包里的文件，默认为no，2.0版本新增的选项

5.mode：解决后文件的权限

6.src：如果copy为yes，则需要指定压缩文件的源路径 

7.owner：解压后文件或目录的属主

具体举例如下：
1、本地压缩包拷贝到远程主机，然后执行解压缩：
ansible web -m unarchive -a 'src=/root/apache-tomcat-8.0.50.tar.gz dest=/usr/local/ copy=yes'

2、直接解压远程主机上的压缩包：
ansible web -m unarchive -a 'src=/opt/jdk-8u181-linux-x64.tar.gz dest=/usr/local/ copy=no'
与之相对的压缩命令的模块是：archive。
```



#### archive压缩命令：

```
查看其文档用法如下：
ansible-doc -s archive|more
打包压缩命令：
ansible web -m archive -a 'path=/data/* format=gz dest=/root/data.tar.gz'
#将远程主机/data/目录下的所有文件和目录打包至dest=/root/data.tar.gz目录中，格式是：gz

ansible web -m archive -a 'path=/etc/* format=gz dest=/root/etc.tar.gz'
#打包etc目录； 将打包文件存放到：/root/etc.tar.gz'
```



#### replace模块：

```
这个模块可以根据我们指定的正则表达式替换文件的匹配的内容。
先看一个例子：
- name: change the start script
  #shell: sed -i "s/^datadir=/datadir=\/data\/mysql/" /etc/init.d/mysqld
  replace: path=/etc/init.d/mysqld replace="datadir={{ datadir_name }}" regexp="^datadir=" backup=yes
  
#安装MySQL的时候，需要修改MySQL的启动脚本，配置datadir参数，这里两行的作用是一样的。只是在执行playbook的时候，使用shell模块会报出警告说建议使用replcae模块。#模块参数如下：path： 指定远程主机要替换的文件的路径。regexp: 指定在文件中匹配的正则表达式，上面匹配以“datadir=”开头的行replace: 指定替换的文件，就是把上面正则匹配到的文件，替换成这里的内容。backup：表示在对文件操作之前是否备份文件。
```



#### lineinfile模块：

```
这个模块会遍历文本中每一行，然后对其中的行进行操作。

1、path参数 ：必须参数，指定要操作的文件。

2、line参数 : 使用此参数指定文本内容。

3、regexp参数 ：使用正则表达式匹配对应的行，当替换文本时，如果有多行文本都能被匹配，则只有最后面被匹配到的那行文本才会被替换，当删除文本时，如果有多行文本都能被匹配，这么这些行都会被删除。

4、state参数：当想要删除对应的文本时，需要将state参数的值设置为absent，absent为缺席之意，表示删除，state的默认值为present。

5、backrefs参数：默认情况下，当根据正则替换文本时，即使regexp参数中的正则存在分组，在line参数中也不能对正则中的分组进行引用，除非将backrefs参数的值设置为yes。　　　　　　backrefs=yes表示开启后向引用，这样，line参数中就能对regexp参数中的分组进行后向引用了，这样说不太容易明白，可以参考后面的示例命令理解。backrefs=yes　　　　　　除了能够开启后向引用功能，还有另一个作用，默认情况下，当使用正则表达式替换对应行时，如果正则没有匹配到任何的行，那么line对应的内容会被插入到文本的末尾，　　　　　　不过，如果使用了backrefs=yes，情况就不一样了，当使用正则表达式替换对应行时，同时设置了backrefs=yes，那么当正则没有匹配到任何的行时，　　　　　　则不会对文件进行任何操作，相当于保持原文件不变。

6、insertafter参数：借助insertafter参数可以将文本插入到“指定的行”之后，insertafter参数的值可以设置为EOF或者正则表达式，EOF为End Of File之意，表示插入到文档的末尾， 　　　　　默认情况下insertafter的值为EOF，如果将insertafter的值设置为正则表达式，表示将文本插入到匹配到正则的行之后，如果正则没有匹配到任何行，则插入到文件末尾，  　　　　当使用backrefs参数时，此参数会被忽略。

7、insertbefore参数：借助insertbefore参数可以将文本插入到“指定的行”之前，insertbefore参数的值可以设置为BOF或者正则表达式，BOF为Begin Of File之意，　　　　　　表示插入到文档的开头，如果将insertbefore的值设置为正则表达式，表示将文本插入到匹配到正则的行之前，如果正则没有匹配到任何行，则插入到文件末尾，　　　　　　当使用backrefs参数时，此参数会被忽略。

8、backup参数：是否在修改文件之前对文件进行备份。

9、create参数 ：当要操作的文件并不存在时，是否创建对应的文件。

在远程主机上创建一个测试文件如下：

[root@docker4 test]# cat mysqld 
[mysqld]
skip-grant-tables
datadir=/data/mysql

datadir is test

[mysqld]
apped this row

然后再ansible主机上测试：
[root@docker5 ~]# cat test.yml 
---
 - hosts: master
   remote_user: root
   gather_facts: no
 
   tasks:
     - name: test the lineinfile module
       lineinfile:
          path=/test/mysqld
          regexp="^\[mysqld\]$"               #匹配以datadir开头的行
          line="test the row..."              #替换为指定的内容

[root@docker5 ~]#
执行上面的剧本，
[root@docker5 ~]# ansible-playbook -i hosts test.yml 
 
PLAY [master] *******************************************************************************************************************************************************************************************

TASK [test the lineinfile module] ***********************************************************************************************************************************************************************
changed: [10.0.102.162]

PLAY RECAP **********************************************************************************************************************************************************************************************
10.0.102.162               : ok=1    changed=1    unreachable=0    failed=0   

[root@docker5 ~]#
#查看内容
[root@docker4 test]# cat mysqld              #这里可以看到只有最后一个匹配的才被替换。
[mysqld]
skip-grant-tables
datadir=/data/mysql

datadir is test

test the row...
apped this row<span class="cnblogs_code_copy"><a title="复制代码"><img id="__LEANOTE_D_IMG_1553660315011" src="/api/file/getImage?fileId=5c9b0c3bdd302f0359000075" alt="复制代码" data-mce-src="/api/file/getImage?fileId=5c9b0c3bdd302f0359000075"></a></span>

继续测试，在[mysqld]下面添加一行logbin=master.
[root@docker5 ~]# cat test.yml 
---
 - hosts: master
   remote_user: root
   gather_facts: no
 
   tasks:
    - name: test the lineinfile module
       lineinfile:
          path=/test/mysqld
          line="log-bin=master"
          insertafter="^\[mysqld\]$"          #设为正则表达式，表示文本插入到匹配行之后。
 
[root@docker5 ~]# ansible-playbook -i hosts test.yml 
 
PLAY [master] *******************************************************************************************************************************************************************************************

TASK [test the lineinfile module] ***********************************************************************************************************************************************************************
changed: [10.0.102.162]
 
PLAY RECAP **********************************************************************************************************************************************************************************************
10.0.102.162               : ok=1    changed=1    unreachable=0    failed=0   

#查看结果如下：[root@docker4 test]# cat mysqld [mysqld]log-bin=masterskip-grant-tablesdatadir=/data/mysqldatadir is testtest the row...apped this row<span class="cnblogs_code_copy"><a title="复制代码"><img id="__LEANOTE_D_IMG_1553660315013" src="/api/file/getImage?fileId=5c9b0c3bdd302f0359000075" alt="复制代码" data-mce-src="/api/file/getImage?fileId=5c9b0c3bdd302f0359000075"></a></span>

```



#### template模块：

```
template模块⽤法和copy模块⽤法基本⼀致，它主要⽤于复制配置⽂件。
ansible-doc -s template

- name: Templates a file out to a remote server. action: template

backup # 拷贝的同时也创建⼀个包含时间戳信息的备份⽂件，默认为no  dest=	#⽬标路径

force  # 设置为yes (默认)时，将覆盖远程同名⽂件。设置为no时，忽略同名⽂件的拷贝group	# 设置远程⽂件的所属组

owner	# 设置远程⽂件的所有者

mode	# 设置远程⽂件的权限。使⽤数值表⽰时不能省略第⼀位，如0644。

# 也可以使⽤'u+rwx' or 'u=rw,g=r,o=r'等⽅式设置

src= # ansible控制器上Jinja2格式的模板所在位置，可以是相对或绝对路径validate       #在复制到⽬标主机后但放到⽬标位置之前，执⾏此选项指定的命令。
# ⼀般⽤于检查配置⽂件语法，语法正确则保存到⽬标位置。
# 如果要引⽤⽬标⽂件名，则使⽤%s，下⾯的⽰例中的s%即表⽰⽬标机器上的/etc/nginx/nginx.conf

  虽然template模块可以按需求修改配置⽂件内容来复制模板到被控主机上，但是有⼀种情况它是不能解决的：不同被控节点所需的配置⽂件差异很⼤，并⾮修改⼏个变量就可以满⾜。例如在centos 6和centos 7上通过yum安装的nginx，它们的配置⽂件内容相差⾮常⼤，且centos 6上的nginx的默认就有⼀个/etc/nginx/conf .d/def ault.conf 。如果直接复制同⼀个模板的nginx配置⽂件到centos 6和centos 7上，很可能导致某⼀版本的nginx不能启动。

ansible centos -m template -a "src=/tmp/nginx.conf.j2 dest=/etc/nginx/nginx.conf
mode=0770 owner=root group=root ba ckup=yes validate='nginx -t -c %s'" -o -f 6

这时就有必要在复制模板时挑选对应发⾏版的模板⽂件进⾏配对复制，例如要复制到 centos6上的源模板是nginx6.conf .j2，复制到cent os 7上的源模板是nginx7 .conf .j2。这种⾏为可以称之为"基于变量选择文件或模板"。

---
- tasks:
- name: template file based var
template: src=/templates/nginx{{ ansible_distribution_major_version }}.conf.j2 dest=/etc/nginx/nginx.conf va lidate="/usr/sbin/nginx -t -c %s"

	还可以在⽂件内容中指定jinja2的替代变量，在ansible执⾏时⾸先会根据变量内容进⾏渲染，渲染后再执⾏相关模块。例如，此处的template模块，复制⼀个基于发⾏版本号的yum源配置⽂件。以下是某个repo⽂件模板base.repo.j2的内容。
	
[epel] 
name=epel
baseurl=http://mirrors.aliyun.com/epel/{{ ansible_distribution_major_version }}Server/x86_64/ 
enable=1
gpgcheck=0

再复制即可
```

#### wait_for模块：

当你利用service 启动tomcat，或数据库后，他们真的启来了么？这个你是否想确认下？ 
wait_for模块就是干这个的。*等待一个事情发生，然后继续*。它可以等待某个端口被占用，然后再做下面的事情，也可以在一定时间超时后做另外的事。

```
connect_timeout：		在下一个事情发生前等待链接的时间，单位是秒，默认值是：5秒

dela：					延时，大家都懂，在做下一个事情前延时多少秒

host：					执行这个模块的host，默认：127.0.0.1

path：					当一个文件存在于文件系统中，下一步才继续。

port：					端口号，如8080

state：					对象是端口的时候start状态会确保端口是打开的，stoped状态会确认端口是关闭的;对象是文件的时候，present或者started会确认文件是存在的，而absent会确认文件是不存在的。
```

