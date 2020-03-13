# 					ansible部署安装及配置：

#### 一、安装方式：

```
ansible的两种安装方式：yum安装和pip安装；
1、yum install ansible -y   #安装epel扩展源：yum install epel-release -y

2、yum install python-pip 

   pip install ansible 
```



#### 二、yum 安装ansible的程序结构：

	　　配置文件目录：/etc/ansible/
	　　执行文件目录：/usr/bin/
	　　Lib库依赖目录：/usr/lib/pythonX.X/site-packages/ansible/
	　　Help文档目录：/usr/share/doc/ansible-X.X.X/
	　　Man文档目录：/usr/share/man/man1/
#### 三、配置：

ansible的配置文件是在：/etc/ansible/ansible.cfg，

##### ansible配置文件常见的参数如下：

```
[defaults]   								通用默认配置段；
inventory      = /etc/ansible/hosts     	    被控端IP或者DNS列表；
library        = /usr/share/my_modules/ 	    Ansible默认搜寻模块的位置；
remote_tmp     = $HOME/.ansible/tmp       Ansible远程执行临时文件；
pattern        = *    				    对所有主机通信；
forks          = 5    					并行进程数；
poll_interval  = 15    					    回频率或轮训间隔时间；
sudo_user      = root   					sudo远程执行用户名；
ask_sudo_pass = True   					使用sudo，是否需要输入密码；
ask_pass      = True    					是否需要输入密码；
transport      = smart   				    通信机制；
remote_port    = 22    					远程SSH端口；
module_lang    = C   					模块和系统之间通信的语言；
gathering = implicit   					    控制默认facts收集（远程系统变量）；
roles_path= /etc/ansible/roles 			    用于playbook搜索Ansible roles；
host_key_checking = False    				检查远程主机密钥；
#sudo_exe = sudo     					    sudo远程执行命令；
#sudo_flags = -H							传递sudo之外的参数；
timeout = 10								SSH超时时间；
remote_user = root   					    远程登陆用户名；
log_path = /var/log/ansible.log     		    日志文件存放路径；
module_name = command 				    Ansible命令执行默认的模块；
#executable = /bin/sh     				    执行的Shell环境，用户Shell模块；
#hash_behaviour = replace    				特定的优先级覆盖变量；
#jinja2_extensions	    				    允许开启Jinja2拓展模块；
#private_key_file = /path/to/file       	    私钥文件存储位置；
#display_skipped_hosts = True     			显示任何跳过任务的状态；
#system_warnings = True    				禁用系统运行ansible潜在问题警告；
#deprecation_warnings = True 				Playbook输出禁用“不建议使用”警告；
#command_warnings = False    			    command模块Ansible默认发出警告；
#nocolor = 1  							输出带上颜色区别，开启/关闭：0/1； 
pipelining = False							开启pipe SSH通道优化；

[accelerate]								accelerate缓存加速。
accelerate_port = 5099
accelerate_timeout = 30
accelerate_connect_timeout = 5.0
accelerate_daemon_timeout = 30
accelerate_multi_key = yes

#/etc/ansible/ansible.cfg中将inventory指令设置为对应的文件或目录即可，如果是目录，那么此目录下的所有文件都是inventory文件。
```

#### 四、ansible配置hosts主机清单：

ansible默认主机清单文件位置：/etc/ansible/hosts，也可以在ansible.cfg配置文件中指定文件位置；

##### ansible常见的连接和权限变量；

```
ansible常见的连接和权限变量：

ansibel_ssh_user=root  		#定义远程主机的用户名，ansible使用这个用户名来连接远程主机；

ansible_ssh_pass='123456' 	#设置远程主机的密码；

ansibel_ssh_port='22'		#远程主机的ssh端口；

ansible_ssh_host： 			#ansible使用ssh要连接的主机；

ansible_ssh_private_key_file： #ssh登录远程用户时的认证私钥；

ansible_connection： #使用何种模式连接到远程主机。默认值为smart(智能)，表示当本地ssh支持持久连接(controlpersist)时采用ssh连接，否则采用python的paramiko ssh连接；

ansible_shell_type： #指定远程主机执行命令时的shell解析器，默认为sh(不是bash，它们是有区别的，也不是全路径)；

ansible_python_interpreter： #远程主机上的python解释器路径。默认为/usr/bin/python；

ansible_*_interpreter：		#使用什么解释器。例如，sh、bash、awk、sed、expect、ruby等等；

其中有几个参数可以在配置文件ansible.cfg中指定，但指定的指令不太一样，以下是对应的配置项：
remote_port： 对应于ansible_ssh_port；

remote_user： 对应于ansible_ssh_user；

private_key_file： 对应于ansible_ssh_private_key_file；

excutable： 对应于ansible_shell_type。但有一点不一样，excutable必须指定全路径，而后者只需指定basename；

如果定义了"ansible_ssh_host"，那么其前面的主机名就称为别名。例如，以下inventory文件中web就是一个别名，真正连接的对象是192.168.83.145。
web ansible_ssh_host=192.168.83.145 ansible_ssh_port=22

当inventory中有任何一台有效主机时，ansible就默认隐式地可以使用"localhost"作为本机，但inventory中没有任何主机时是不允许使用它的，且"all"或"*"所代表的所有主机也不会包含localhost。例如：
1.ansible localhost -i /path/to/inventory_file -m MODULE -a "ARGS"

2.ansible all -i /path/to/inventory_file -m MODULE -a "ARGS"

3.ansible * -i /path/to/inventory_file -m MODULE -a "ARGS"

inventory_hostname是ansible中可以使用的一个变量，该变量代表的是每个主机在inventory中的主机名称。例如"192.168.100.59"。这是目前遇到的第一个变量。
```

##### 定义主机组和变量：

```
示例一：
[web]	#定义一个组名为web的主机组；
192.168.83.146 ansibel_ssh_user=root ansible_ssh_pass='123456' ansibel_ssh_port='22'
192.168.83.147 ansibel_ssh_user=root ansible_ssh_pass='123456' ansibel_ssh_port='22'
192.168.83.148 ansibel_ssh_user=root ansible_ssh_pass='123456' ansibel_ssh_port='22'

示例二：
[web]
192.168.83.145:22	#指定了远程主机的ssh连接端口
192.168.83.14[6:8]  #表示设置了三台主机IP地址：146、147、148；
[web:vars]			#定义了要传递给web主机组的变量,若定义为"[all:vars]"或"[*:vars]"则表示传递给所有主机的变量;
ansible_ssh_user=root	#定义远程主机的用户名，ansible使用这个用户名来连接远程主机；
ansible_ssh_pass='123456' #设置远程主机的密码；
ansibel_ssh_port='22'		#远程主机的ssh端口；

示例三：
[webservers:children] #定义了一个新的主机组webservers，该组的组成员有web组。
web					  #web组名，web组的所有成员；
```

