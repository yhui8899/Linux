## Samba服务器

```
yum install -y samba samba-server samba-client samba-common
```

**匿名用户修改配置文件如下：**

```
vim /etc/samba/smb.conf
[global]                              
workgroup = SAMBA             
security = user            
map to guest = Bad User       
passdb backend = tdbsam    
log file = /var/logs/samba/log.%m           
   
 printing = cups
    printcap name = cups
    load printers = yes
    cups options = raw
[homes]                                
comment = Home Directories        
    valid users = %S, %D%w%S           
    browseable = No                    
read only = No                     
    inherit acls = Yes
[test]
comment = This is Logs
path = /www/webapp/
writable = yes 
browseable = yes                
guest ok = yes   
```



chown nobody:nobody /www/webapp/    #授予匿名权限

**配置文件详解：**



```
[global]                                     

#全局配置，PS:该项对整个samba服务都有效

workgroup = SAMBA                        

#服务器工作组名称

security = user                              

#安全级别；可设置多个级别【share | user| server | domain 

map to guest = Bad User                  

#允许匿名用户访问（Ps:配置smba匿名访问全局参数时，centos7是不支持share参数的“share”参数的，所以需要添加map to guest = bad user一列，）



passdb backend = tdbsam                       

#设置共享账号文件类型，默认tdbsam(TDB数据文件)

log file = /var/logs/samba/log.%m                

#日志文件位置



printing = cups

printcap name = cups

load printers = yes

cups options = raw



[homes]                                   

#宿主机共享目录

comment = Home Directories            

#描述信息

valid users = %S, %D%w%S           

browseable = No                        

#是否可见，设置NO时，相当于隐藏文件

read only = No                          

#不只读为NO

inherit acls = Yes



[test]

comment = This is Logs

path = /www/webapp/

writable = yes 

browseable = yes                 

#浏览器权限开启

guest ok = yes                   

#是否允许匿名用户访问


```



**【用户访问验证访问】**

建立Samba用户数据库

```
useradd -s /sbin/nologin  smbtest     #添加系统用户*

smbpasswd -a smbtest或者pdbedit -a -u smbtest   #添加Samba用户并设置密码（该用户必须是系统用户）

pdbedit -L    #列出samba所有用户

pdbedit -Lv testadm     #列出samba用户，输出详细信息
```

**配置文件如下**

```
vim /etc/samba/smb.conf

[global]

security = user

socket address = 192.168.72.222    #本机IP

[testadm_file]

path = /www/test01/     		#Samba需要共享目录

browseable = yes     		#是否显示共享目录，设置为no，则隐藏

read only = no        		#只读，这是为no可写可读，设置为yes，仅仅能读

valid users = smbtest      #设置访问共享用户

Encrypt passwords = yes    #加密密码

\#hosts allow        		#允许哪些主机可以访问



\#write list          		#设置允许哪些用户可写
```



systemctl restart smb   #重启Samba服务器
----------------------------------------------------
Linux挂载Samba：
mount -t cifs //192.168.72.222/testadm_file -o username=smbtest,password=123
