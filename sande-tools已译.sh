#!/bin/bash

#Java env      #jdk变量
JAVA_HOME=/usr/local/jdk
PATH=$JAVA_HOME/bin:$PATH
CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export JAVA_HOME
export PATH
export CLASSPATH

# Source function library.
. /etc/init.d/functions

if [[ $# -eq 0 ]]; then
    echo $"Usage: $0 {stop|start|restart|update|restore|backup|log}"
    echo $"Usage: $0 [AppName] update [WarName]"
    exit 2
fi

Date=`date +%Y%m%d`													#日期时间
LogDate=`date '+%Y-%m-%d %H:%M'`									#日志日期时间
AppName=$1															#应用名称
WebName=$3															#Web名称
UpdateDir=/home/yunwei/update										#更新目录
BackupAllDir=/home/yunwei/backup									#全量备份
BackupDir=/home/yunwei/backup/bak${Date}/$AppName					#备份目录+备份日期+应用名称
UpdateLog=/tmp/sd_update.log										#更新日志
AllTomcatExampleDir=`ps -ef |grep "tomcat" |grep -v grep |grep "Dcatalina.home=" |awk -F"-Dcatalina.home=" '{print $2}' | awk -F" " '{print $1}'`    #获取tomcat目录
TomcatExampleDir=/usr/local/$AppName							
#判断tomcat目录中的server.xml 配置文件是否存在	
if [[ ! -f $TomcatExampleDir/conf/server.xml ]]; then			
    action "No $AppName tomcat project." /bin/false
    exit 1
fi

TomcatDataDir=`grep "docBase=" $TomcatExampleDir/conf/server.xml |grep -v grep |awk -F" " '{print $2}' |awk -F"\"" '{print $2}'`   #tomcat的发布目录
WarName=`echo $TomcatDataDir | awk -F "/" '{print $NF}'`       #显示应用名称

StartPid=`ps aux | grep -w "$AppName" | grep "Dcatalina.home=" | grep -v grep | grep -v "$0" | awk '{print $2}'`     #找出tomcat应用的进程ID


service_usage () {												#使用帮助提示；
    echo $"Usage: $0 {stop|start|restart|update|restore}"
    echo $"Usage: $0 [AppName] update [WarName]"
    exit 2
}

check_war_name () {
    if [[ ${WebName} != ${WarName}  && ${WebName} != ${WarName}.war ]]; then      #检查应用名称和war包名称是否一致，不一致则退出
        action "$WebName is unavailable." /bin/false
        exit 1
    fi
}

check_app_name () {
    echo "$AllTomcatExampleDir" | grep -q "$AppName"   #检查tomcat目录和应用名称是否一致
    if [[ $? -ne 0 ]]; then
        action "$AppName not running,please check $AppName stat" /bin/false
        exit 1
    fi
}

check_update_dir_data () {
	if [[ ! -e $UpdateDir/$WebName ]]; then							#判断更新目录下的web名称是否存在，-e 表示存在，则为真，不存在就退出！
		action "$AppName no update data" /bin/false
		exit 1														
	elif [[ -d $UpdateDir/$WarName/$WarName ]]; then				#判断更新目录下的WAR名称，不可用则退出！
		action "$WarName zip Pack Dir error" /bin/false
		exit 1
    fi
}

check_bak_data () {
    LsBakData=`ls -A $BackupDir 2>/dev/null`
    if [[ "$LsBakData"  = "" ]];then							# 判断备份目录home/yunwei/backup/bak${Date}/$AppName是否为空
        action "$AppName no backup data." /bin/false
        exit 1
    fi
}


service_stop () {									#停止tomcat服务
    if [[ -z $StartPid ]]; then						#检测tomcat的PID是否存在
        echo "The $AppName Tomcat project not running." 
    else
        kill -9 $StartPid &>/dev/null				#kill掉tomcat进程ID
            CheckPid=`ps aux | grep -w "$AppName" | grep "Dcatalina.home=" | grep -v grep | grep -v "$0" | awk '{print $2}'`		#检查tomcat的进程ID是否存在
                [ -z $CheckPid ] && action "Stoping $AppName:" /bin/true || action "Stoping $AppName:" /bin/false 
    fi
}

service_start () {									#启动tomcat服务
    CheckStartPid=`ps aux | grep -w "$AppName" | grep "Dcatalina.home=" | grep -v grep | grep -v "$0" | awk '{print $2}'`		#检测tomcat的PID是否存在
        if [[ "$CheckStartPid" = "" ]]; then													#判断tomcat的进程ID是否存在，不存在则启动
            $TomcatExampleDir/bin/startup.sh 1>/dev/null
                CheckPid=`ps aux | grep -w "$AppName" | grep "Dcatalina.home=" | grep -v grep | grep -v "$0" | awk '{print $2}'`			#检查tomcat的进程ID是否存在
                     [ -n $CheckPid ]  && action "Starting $AppName:" /bin/true || action "Starting $AppName:" /bin/false					#tomcat进程ID存在返回真true，不存在返回假 false；
        else
            echo "$AppName is start."
        fi
}

service_backup () {									 #数据备份
    if [[ ! -d $BackupDir ]]; then					 #判断备份目录home/yunwei/backup/bak${Date}/$AppName是否存在，不存在则创建
        mkdir -p $BackupDir
    fi

    if [[ "`ls -A $BackupDir`" != ""  ]]; then			#查看备份目录是否为空，如果有备份文件则跳过备份，否则将数据目录拷贝到备份目录
        echo "Backup already exists, skip backup."
    else
    \cp -pa $TomcatDataDir $BackupDir					#将数据目录拷贝到备份目录
        if [[ $? -eq 0 ]]; then														#判断数据备份是否成功，成功返回真true，失败返回假false；
            action "${BackupDir} -- $app_name Backup Complete." /bin/true    
        else
            action "${BackupDir} -- $app_name Backup failed." /bin/false
        fi
    fi
}

service_update () {
    if [[ "$WebName" = "$WarName" ]]; then    				#判断web名称和war名称名称是否一致；		
        service_incremental_update     						#执行：service_incremental_update模块进行增量更新
    elif [[ "$WebName" = "$WarName.war" ]]; then			#判断web名称等于war名称.war ，则执行：service_full_update  进行全量更新
        service_full_update									#执行service_full_update  进行全量更新
    else
        action "The $WebName unavailable, Please enter the correct name." /bin/false			#如果不符合以上规则 返回假 false；并退出
        exit 1
    fi

}


service_full_update () {												#全量更新模块
    rm -fr $TomcatDataDir/*												#清空数据目录
    unzip -qo $UpdateDir/$WebName  -d $TomcatDataDir					#解压更新目录下的软件包到tomcat的数据目录；
        if [[ $? -eq 0 ]]; then
            action "$AppName Full Update complete." /bin/true			#解压成功返回真：true  否则返回假：false 并退出；
        else
            action "$AppName Full Update failed." /bin/false
            exit 1
        fi
}

service_incremental_update () {												#增量更新模块
        \cp -pa $UpdateDir/$WarName/* $TomcatDataDir						#拷贝更新目录下的war名称目录下的所有文件到tomcat的发布目录
            if [[ $? -eq 0 ]]; then
                action "$AppName Incremental Update complete." /bin/true	#拷贝成功返回真：true  否则返回假：false 并退出；
            else
                action "$AppName Incremental Update failed." /bin/false
                exit 1
            fi
}

service_restore () {														#回滚模块	
    if [[ "`ls -A $BackupDir`" != "" ]]; then
        rm -fr $TomcatDataDir/*												#清空数据目录
        \cp -fr $BackupDir/$WarName/* $TomcatDataDir						#拷贝备份目录下的应用到tomcat的数据目录
        action "$AppName Restore complete." /bin/true						#拷贝成功返回真：true  否则返回假：false并退出；
    else
        action "No Badkup data." /bin/false
        exit 1
    fi
}

service_log () {   															#服务日志模块；
    tailf -300 $TomcatExampleDir/logs/catalina.out							#查看最后300行的tomcat日志
}

service_del_bak () {														#删除30天以前的备份文件
    find $BackupAllDir -name "bak*" -type d -mtime +30 | xargs rm -rf		#查找全量备份目录下30天之前以bak开头的目录并删除；
}

service_update_log () {														#服务更新日志模块
    echo "$AppName ---> $LogDate ---> $WebName" >> $UpdateLog               #日志文件路径：/tmp/sd_update.log
}

case "$2" in
    stop )
        [ $# -ne 2 ] && { service_usage; exit; }        #变量的个数少于2个则提示：service_usage模块的命令
        service_stop			                        #执行service_stop 模块的命令	                        
        ;;

    start )
        [ $# -ne 2 ] && { service_usage; exit; }		#变量的个数少于2个则提示：service_usage模块的命令
        service_start
        ;;

    restart )
        [ $# -ne 2 ] && { service_usage; exit; }		#变量的个数少于2个则提示：service_usage模块的命令
        service_stop
        sleep 3
        service_start
        ;;

    update )											
        [ $# -ne 3 ] && { service_usage; exit; }		#变量的个数少于3个则提示：service_usage模块的命令
        check_app_name									#执行check_app_name 检查tomcat的软件安装目录
        check_war_name									#执行check_war_name 检查war名称或名称.war包
        check_update_dir_data							#执行check_update_dir_data 检查更新目录文件
        service_stop									#执行service_stop 停止tomcat服务
        service_backup									#数据目录备份
        service_update									#执行service_update模块的命令进行更新
        sleep 3											#等待3秒
        service_start									#启动tomcat服务
	service_update_log									#显示更新日志
	service_del_bak										#删除30天以前的备份文件
        ;;

    checkdir )
	[ $# -ne 3 ] && { service_usage; exit; }			#变量的个数少于3个则提示：service_usage模块的命令
	check_update_dir_data								
	;;

    restore )											#回滚
        [ $# -ne 2 ] && { service_usage; exit; }		#脚本的参数个数小于2 则提示usage使用帮助；
        check_app_name 									#执行check_app_name 检查tomcat的软件安装目录
        check_bak_data									#检查备份日期
        service_stop									#停止tomcat服务
        service_restore									#回滚数据文件
        service_start									#启动tomcat服务
        ;;

    backup )											#备份
        [ $# -ne 2 ] && { service_usage; exit; }
        service_backup									#数据备份
        ;;

    log )												#日志
        [ $# -ne 2 ] && { service_usage; exit; }
        service_log										#查看最后300行的tomcat日志
        ;;

    * )													#usage使用帮助
        service_usage
        ;;
esac
exit 0
