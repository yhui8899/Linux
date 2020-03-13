# 							yaml文件编写

##### ansible的playbook采用yaml语法，它简单地实现了json格式的事件描述。yaml之于json就像markdown之于html一样，极度简化了json的书写。在学习ansible playbook之前，很有必要把yaml的语法格式、引用方式做个梳理。

```
1、 yaml文件以---开头，以表明这是一个yaml文件，就像xml文件在开头使用<?xml version="1.0" encoding="utf-8"?>宣称它是xml文件一样。但即使没有使用---开头，也不会有什么影响。

2、yaml中使用"#"作为注释符，可以注释整行，也可以注释行内从"#"开始的内容。

3、 yaml中的字符串通常不用加任何引号，即使它包含了某些特殊字符。但有些情况下，必须加引号，最常见的是在引用变量的时候。具体见后文。

4、 关于布尔值的书写格式，即true/false的表达方式。其实playbook中的布尔值类型非常灵活，可分为两种情况：

5、 模块的参数： 这时布尔值作为字符串被ansible解析。接受yes/on/1/true/no/off/0/false，这时被ansible解析。例如上面示例中的update_cache=yes。

\6.6、true/yes/on/y/false/no/off/n。例如上面的gpgcheck=no和enabled=True。

建议遵循ansible的官方规范，模块的布尔参数采用yes/no，非模块的布尔参数采用True/False
```

#### task分文三类：pre_tasks、tasks、post_tasks

##### 1、pre_tasks： 最先执行的任务，一般放在前面，

##### 2、post_tasks：最后执行的任务；

```
检测yaml文件格式是否有错误：

ansible-playbook --syntax-check  test.yaml

使用ansible-playbook执行yaml文件

ansible-playbook test.yaml
```

##### 编写安装mariadb数据库为例：

```
---
   - hosts: web
     remote_user: root
     pre_tasks:
       - name: set epel repo for Centos 7
         yum_repository:
           name: epel7
           description: epel7 on CentOS 7
           baseurl: http://mirrors.aliyun.com/epel/7/$basearch/
           gpgcheck: no
           enabled: True
     tasks:
       - name: install mariadb
         yum: name=mariadb-server,mariadb-devel state=present
       - name: started mariadb service
         service: name=mariadb state=started enabled=true
       - name: check auto start setting
         command: 'systemctl is-enabled mariadb'
```

##### 卸载mariadb数据库：

```
---
   - hosts: web
     remote_user: root
     gather_facts: false			#TASK [Gathering Facts]，关闭此信息，默认是开启的；
     pre_tasks:
       - name: set epel repo for Centos 7
         yum_repository:
           name: epel7
           description: epel7 on CentOS 7
           baseurl: http://mirrors.aliyun.com/epel/7/$basearch/
           gpgcheck: no
           enabled: True
     tasks:
       - name: remove mariadb
         yum: name=mariadb-server,mariadb-devel state=absent
       - name: check mariadb uninstall
         shell: echo `rpm -qa mariadb` >/tmp/mariadb_uninstall.log

```

#### yaml文件中调用变量：

```
1、操作系统变量可以直接使用：${变量名} 来引用变量；

    示例：	echo ${hostname}

2、用户变量，用户定义的临时环境变量调用方式：{{lookup('env','变量名')}} 示例如下：

	示例：echo： {{lookup('env','message')}}
	#通过lookup来调用变量，首先会去找‘env’然后再去找变量名‘message’
	#取消环境变量：unset message
	
3、yaml文件中指定的变量，调用方法：{{MESSAGE}},定义方法如下：
    yaml文件中定义变量示例：
    vars:
      - MESSAGE: xiaofeige
      - 变量名： 变量值
    #定义全局变量一般在第三行定义即可；  


```

#### when条件判断：

以判断操作系统为例：

```
---
  - hosts: web1
    gather_facts: true				#gather_facts走的是setup模块；
    tasks:
      - name: check systemctl version
        shell: echo "RedHat" `date` by `hostname` >>/tmp/if.log
        when: ansible_os_family =='RedHat'
      - name: say other linux hello task
        shell: echo 'Not RedHat' `date` by `hostname` >>/tmp/if.log
        when: ansible_os_family !='RedHat'

以上有两个when判断：
1、when: ansible_os_family =='RedHat' #判断如果操作系统是RedHat就输出：echo "RedHat" `date` by `hostname` >>/tmp/if.log

2、 when: ansible_os_family !='RedHat' #判断如果操作系统是RedHat就输出：echo 'Not RedHat' `date` by `hostname` >>/tmp/if.log

3、需要采集ansible_os_family变量需要打开：gather_facts: true，因为走的是setup模块的变量：
```

#### setup模块变量如下：

```
ansible_nodename 		节点名字
ansible_form_factor 	服务器类型
ansible_virtualization_role 	虚拟机角色（宿主机或者虚拟机）
ansible_virtualization_type 	虚拟机类型（kvm）
ansible_system_vendor 	供应商（Dell）
ansible_product_name 	产品型号（PowerEdge R530）
ansible_product_serial 	序列号（sn）
ansible_machine   	计算机架构（x86_64）
ansible_bios_version 	BIOS版本
ansible_system 		操作系统类型（linux）
ansible_os_family 	操作系统家族（RedHat）
ansible_distribution 	操作系统发行版（CentOS）
ansible_distribution_major_version 		操作系统发行版主版本号（7）
ansible_distribution_release 		操作系统发行版代号（core）
ansible_distribution_version 		操作系统发行版本号（7.3.1611）
ansible_architecture 		体系（x86_64）
ansible_kernel 		操作系统内核版本号
ansible_userspace_architecture 		用户模式体系（x86_64）
ansible_userspace_bits 		用户模式位数
ansible_pkg_mgr 		软件包管理器
ansible_selinux.status selinux状态  #--------------------------------------------
ansible_processor 		CPU产品名称
ansible_processor_count 	CPU数量
ansible_processor_cores 	单颗CPU核心数量
ansible_processor_threads_per_core 	每个核心线程数量
ansible_processor_vcpus 		CPU核心总数
ansible_memtotal_mb 		内存空间
ansible_swaptotal_mb 		交换空间
ansible_fqdn 		主机的域名
ansible_default_ipv4.interface 	默认网卡
ansible_default_ipv4.address 	默认IP地址
ansible_default_ipv4.gateway 	默认网关

********* json 格式 ********
ansible_devices 		硬盘设备名
ansible_devices.vendor 	硬盘供应商
ansible_devices.model 	硬盘整列卡型号 
ansible_devices.host 	硬盘整列卡控制器
ansible_devices.size 	设备存储空间

********* json 格式 ********
ansible_interfaces 		网卡
ansible_{interfaces}.ipv4.address 		网卡IP地址
ansible_{interfaces}.ipv6.0.address 	网卡IPv6地址
ansible_{interfaces}.macaddress 		网卡mac地址

```

#### for循环：

```
---
  - hosts: web
    gather_facts: true
    tasks:
      - name: say RedHat hello task
        shell: echo {{item}} `date` by `hostanme` >>/tmp/for.log
        with_items:
          - message item1
          - message item2
          - message item3
          - message item4
          - message item5
          
 1、定义一个item变量：与shell中的for一样，循环5次赋值给：with_items
 	 with_items:
          - message item1
          - message item2
          - message item3
          - message item4
          - message item5
2、调用变量：echo {{item}}，
#item变量名的值就是：with_items，因为- message item1赋值给：with_items
注意：item变量名对应的是：with_items 是固定的不能修改；
```

常用循环语句：

| 语句          | 描述         |
| ------------- | ------------ |
| with_items    | 标准循环     |
| with_fileglob | 遍历目录文件 |
| with_dict     | 遍历字典     |

```
标准循环
tasks:
- name： 批量创建用户
  user: name={{ item }} state=present groups=wheel
  with_items:
     - testuser1
     - testuser2
```

```
遍历目录文件
- name: 解压
  copy: src={{ item }} dest=/tmp
  with_fileglob:
    - "*.txt"
```

run_once: true		#代表执行一次就不执行了；

---------------------

### Hosts:

```
inventory:			#指定我们要控制的主机

	group_vars:		#存放所有控制主机的公共变量

		all.yaml
```



## role目录结构：

```
defaults：	#默认的变量，优先级最低的

files：		#静态的无法变化的配置文件，需要复制到客户端的文件

handlers:	#服务类，启动服务，设置开机启动

tasks:		#任务类，安装软件

templates：	#动态的配置文件吗，如：nginx.conf.j2,是j2格式的模板文件,所有任务需要用到的模板存放目录

vars:		#自定义变量

mate：		#元数据，即是调用其他roles的任务等，比较少用到！
```

### include引用案例：

#### 示例一：

```
---
  - hosts: web
    tasks: 
      - include_tasks: wordpress.yaml wp_user=user1
      - include_tasks: wordpress.yaml wp_user=user2
#1、使用include引用wordress.yaml文件里面的任务；
#2、变量传递，定义变量wp_user=user1将变量传递给WordPress.yaml文件来调用；

```

#### 示例二：

```
---
  - hosts: web
    tasks:
      - include_tasks: check_address.yaml
```

### roles：

```
---
  - hosts:
    roles:
      - {role: role1,port:5001}	#带结构体的方式指定，这里的变量优先级是最高的，会替换role里面的变量
      - {role: role2,when: "ansible_os_family == 'RedHat'"} #添加条件判断，如果OS系统是RedHat的话就执行role2角色
      
#yml里面的变量优先级大于vars目录的，大于default下面的变量，yml>vars>defaults

```

### 个别参数注解：

```
#chdir: 进入目录，和cd一样,是command模块中的参数；
#ignore_errors: yes		#如果这个任务执行错了还可以继续执行下一个任务；   
------------------------
hosts用于指定要执行指定任务的主机，其可以是一个或多个由逗号分隔主机组；remote_user则用于指定远程主机上的执行任务的用户。如上面示例中的

        - hosts: websrvs

          remote_user:xiaofeige   #在远程主机上以哪个用户身份执行

          become: yes   #是否允许身份切换

          become_method: sudo   #切换用户身份的方式，有sudo、su、pbrun等方式，默认为sudo

          become_user: root   #切换成什么用户身份，默认为root
```

