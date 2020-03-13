#!/bin/bash
# Author: xiaofeige
# QQ: 355638930
# ansible update shell

# Source function library.
. /etc/init.d/functions

#Use
if [[ $# -eq 0 ]]; then
	echo $"Usage: $0 [AppName] {stop|start|restart|restore|backup}"
	echo $"Usage: $0 [AppName] zipupdate {restart|norestart}"
	echo $"Usage: $0 [AppName] warupdate"
	echo $"Usage: $0 haproxy|nginx {deny|allow}"
	echo $"Usage: $0 [AppName] {zipdown|wardown}"
	exit 2
fi

service_usage () {
	echo $"Usage: $0 [AppName] {stop|start|restart|restore|backup}"
	echo $"Usage: $0 [AppName] zipupdate {restart|norestart}"
	echo $"Usage: $0 [AppName] warupdate"
	echo $"Usage: $0 haproxy|nginx {deny|allow}"
	echo $"Usage: $0 [AppName] {zipdown|wardown}"
	exit 2
}

Date=`date +%Y%m%d`
LogDate=`date '+%Y-%m-%d %H:%M'`
AppName=$1
SeStatus=$2
ReStatus=$3

Command="ansible $AppName -m shell -a"	
HaCommand="ansible haproxy -m shell -a"
NgCommand="ansible nginx36 -m shell -a"
DoCommand="ansible download -m shell -a"

WarUrl="http://192.168.6.37:6789/qltwar"
ZipUrl="http://192.168.6.37:6789/qltzip"
ZipUrl30="http://192.168.1.30:6789/chaozhigou/prod/zippack"

HaDir="/usr/local/haproxy/conf"
NgDir="/usr/local/nginx/conf/vhost"
UpDir="/home/yunwei/update"
DoZDir="/data/download/qltzip"
DoWdir="/data/download/qltwar"
TomcatDir="/usr/www"
AnLog="/tmp/ansible-tools.log"


#Close Wlan Access
close_html () {																#关闭外网访问
	$HaCommand "sudo \cp -pa $HaDir/haproxy.cfgbaku $HaDir/haproxy.cfg"		#覆盖原来的haproxy配置文件：ansible haproxy -m shell -a "sudo \cp -pa /usr/local/haproxy/conf/haproxy.cfgbaku  /usr/local/haproxy/conf/haproxy.cfg"
	$HaCommand "sudo /etc/init.d/haproxy restart"							#重启haproxy服务：ansible haproxy -m shell -a "sudo /etc/init.d/haproxy restart"
	$NgCommand "sudo \cp -pa $NgDir/*.conf $NgDir/QLTBAK/"					#备份nginx配置文件：ansible nginx36 -m shell -a "sudo \cp -pa /usr/local/nginx/conf/vhost/*.conf /usr/local/nginx/conf/vhost/QLTBAK/"
	$NgCommand "sudo \cp -pa $NgDir/UPDATE/*.conf $NgDir/"			#将UPDATE下的配置文件覆盖vhost的配置文件ansible nginx36 -m shell -a "sudo \cp -pa /usr/local/nginx/conf/vhost/UPDATE/*.conf /usr/local/nginx/conf/vhost/"
	$NgCommand "sudo /etc/init.d/nginx -s reload"					#重启nginx ：ansible nginx36 -m shell -a "sudo /etc/init.d/nginx -s reload"
	action "haproxy nginx36 close" /bin/true						
}

#Allow Wlan Access
allow_html () {
	$HaCommand "sudo \cp -pa $HaDir/haproxy.cfgall $HaDir/haproxy.cfg"			#还原haproxy.cfg配置文件
	$HaCommand "sudo /etc/init.d/haproxy restart"								#重启haproxy服务
	$NgCommand "sudo \cp -pa $NgDir/QLTBAK/*.conf $NgDir/"						#还原nginx配置文件
	$NgCommand "sudo /etc/init.d/nginx -s reload"								#重启nginx服务
	action "haproxy nginx36 allow" /bin/true
}

#service list
service_start () {									
	$Command "sande-tools.sh tomcat-$AppName start"			#启动tomcat-应用名称：ansible $AppName -m shell -a "sande-tools.sh  tomcat-应用名称 start"    #调用远程sande-tools.sh 脚本执行启动命令
}

service_stop () {
	$Command "sande-tools.sh tomcat-$AppName stop"			#停止tomcat服务：ansible $AppName -m shell -a "sande-tools.sh  tomcat-应用名称 start"    #调用远程sande-tools.sh 脚本执行启动命令
}

service_restart () {
	$Command "sande-tools.sh tomcat-$AppName restart"		#重启tomcat服务：ansible $AppName -m shell -a "sande-tools.sh  tomcat-应用名称 restart"    #调用远程sande-tools.sh 脚本执行启动命令
}

service_restore () {
	$Command "sande-tools.sh tomcat-$AppName restore"		#回滚：ansible $AppName -m shell -a "sande-tools.sh  tomcat-应用名称 restore"    #调用远程sande-tools.sh 脚本执行启动命令
}

service_backup () {
	$Command "sande-tools.sh tomcat-$AppName backup"		#备份tomcat：ansible $AppName -m shell -a "sande-tools.sh  tomcat-应用名称 backup"    #调用远程sande-tools.sh 脚本执行启动命令
}

service_zipdown () {
	$DoCommand "rm -rf $DoZDir/${AppName}.zip"					#删除原zip包： ansible download -m shell -a "rm -fr /data/download/qltzip/应用名称.zip"
	$DoCommand "wget -cN -P $DoZDir $ZipUrl30/${AppName}.zip"	#下载增量更新的zip包： ansible download -m shell -a "wget -cN -P /data/download/qltzip  http://192.168.1.30:6789/chaozhigou/prod/zippack/应用名称.zip" 
}																													#下载的更新包在：/data/download/qltzip目录中

service_wardown () {
	$DoCommand "wgetwar.sh $AppName"							#下载全量更新包：ansible download -m shell -a "wgetwar.sh 应用名称"    调用6.37的wgetwar.sh 脚本
}

#War pack update
check_war_pack () {
	CheckUrl=`wget --spider $WarUrl/${AppName}.war > /dev/null 2>&1`    #检查war包 ：wget --spider http://192.168.6.37:6789/qltwar/应用名称.war    --spider ：不下载
	if [[ $? -eq 0 ]]; then
		$Command "rm -rf $UpDir/${AppName}*"										#删除原来的更新包：ansible $AppName -m shell -a "rm -fr /home/yunwei/update/应用名称*"
		$Command "wget -cNq -P $UpDir $WarUrl/${AppName}.war > /dev/null 2>&1"		#下载更新包：ansible $AppName -m shell -a "wget -cNq -P /home/yunwei/update/ http://192.168.6.37:6789/qltwar/应用名称.war"  
		if [[ $? -eq 0 ]]; then						#判断上一条命令执行成功返回真：true 否则返回假：false 并退出；   #wget参数：-c (断点续传)、-N（除非远程文件较新，否则不再取回）、-q(安静模式(不输出信息))、-P(指定目录)
			action "$AppName War Pack download Success" /bin/true					
		else
			action "$AppName War Pack download false" /bin/false
			exit 1
		fi
	else
		action "$AppName War Pack false" /bin/false
		exit 1
	fi
}

service_warupdate () {
	$Command "sande-tools.sh tomcat-$AppName update ${AppName}.war"			#全量更新：ansible $AppName -m shell -a "sande-tools.sh tomcat-$AppName update ${AppName}.war
	action "$AppName war update Success" /bin/true
}

#zip update, restart or norestart
check_zip_pack () {
	CheckUrl=`wget --spider $ZipUrl/${AppName}.zip > /dev/null 2>&1`		#检查增量更新包：wget --spider http://192.168.6.37:6789/qltzip/${AppName}.zip 
	if [[ $? -eq 0 ]]; then													#判断上一条命令执行成功，如果不成功直接退出；
		$Command "rm -rf $UpDir/${AppName}*"								#删除原更新目录中的文件：ansible $AppName -m shell -a "rm -rf /home/yunwei/update/${AppName}*"
		$Command "wget -cNq -P $UpDir $ZipUrl/${AppName}.zip"				#下载增量更新包到/home/yunwei/update目录：ansible $AppName -m shell -a "wget -cNq -P /home/yunwei/update http://192.168.6.37:6789/qltzip/${AppName}.zip"
		if [[ $? -eq 0 ]]; then							
			action "$AppName zip Pack download Success" /bin/true
		else
			action "$AppName zip Pack download false" /bin/false
			exit 1
		fi
	else
		action "$AppName zip Pack Non-existent" /bin/false
		exit 1
	fi
}

service_zipupdate_restart () {												#增量更新重启
	$Command "unzip -o $UpDir/${AppName}.zip -d $UpDir"						#解压增量更新包文件：ansible $AppName -m shell -a "unzip -o /home/yunwei/update/${AppName}.zip  -d /home/yunwei/update"
	$Command "sande-tools.sh tomcat-$AppName update $AppName"				#增量更新：ansible $AppName -m shell -a  "sande-tools.sh tomcat-$AppName update $AppName"
	action "$AppName zip update restart" /bin/true
}

service_zipupdate_norestart () {											#增量更新不重启
	$Command "unzip -o $UpDir/${AppName}.zip -d $UpDir"						#解压增量更新包文件：ansible $AppName -m shell -a "unzip -o /home/yunwei/update/${AppName}.zip  -d /home/yunwei/update"
	$Command "sande-tools.sh tomcat-$AppName checkdir $AppName"				#检查数据目录是否存在：ansible $AppName -m shell -a  "sande-tools.sh tomcat-$AppName checkdir $AppName"
	$Command "\cp -pa $UpDir/$AppName/* $TomcatDir/$AppName/"				#增量更新：ansible $AppName -m shell -a "\cp -pa /home/yunwei/update/$AppName/* /usr/www/$AppName/"
	action "$AppName zip update Norestart" /bin/true
}

service_zipupdate () {														#增量更新
	if [[ "$ReStatus" = "restart" ]]; then									#判断增量更新状态=restart则执行：service_zipupdate_restart ， 判断更新状态=norestart则执行：service_zipupdate_norestart
		service_zipupdate_restart  
	elif [[ "$ReStatus" = "norestart" ]]; then
		service_zipupdate_norestart
	else
		action "$ReStatus error, only support restart|norestart" /bin/false
		exit 1
	fi
}

service_log () {															#查看日志
	echo "$AppName ---> $LogDate ---> $SeStatus" >> $AnLog					#日志追加到：/tmp/ansible-tools.log
}

service_ziplog () {
	echo "$AppName ---> $LogDate ---> $SeStatus --> $ReStatus"  >> $AnLog      #日志追加到：/tmp/ansible-tools.log
}

case "$2" in
	zipdown )											#下载增量更新包
		[ $# -ne 2 ] && { service_usage; exit; }
		service_zipdown
		service_log
		;;

	wardown )											#下载全量更新包
		[ $# -ne 2 ] && { service_usage; exit; }
		service_wardown
		service_log
		;;

	deny )												#关闭外网访问
		[ $# -ne 2 ] && { service_usage; exit; }
		close_html						
		service_log
		;;

	allow )												#开启外网访问
		[ $# -ne 2 ] && { service_usage; exit; }
		allow_html
		service_log
		;;

    stop )												#停止tomcat服务 如：tomcat-api
        [ $# -ne 2 ] && { service_usage; exit; }
        service_stop
		service_log
        ;;

    start )												#启动tomcat服务  如：tomcat-api
        [ $# -ne 2 ] && { service_usage; exit; }
        service_start
		service_log
        ;;

    restart )											#重启tomcat服务  如：tomcat-api
        [ $# -ne 2 ] && { service_usage; exit; }
		service_restart
		service_log
        ;;

	warupdate )											#全量更新
		[ $# -ne 2 ] && { service_usage; exit; }
		check_war_pack
		service_warupdate
		service_log
		;;

    zipupdate )											#增量更新
        [ $# -ne 3 ] && { service_usage; exit; }
		service_zipdown									#下载增量更新包
		check_zip_pack									#检查增量更新包并下载至$AppName的/home/yunwei/update目录  
		service_zipupdate								#增量更新
		service_ziplog									#显示增量更新日志
        ;;

    restore )											#回滚
        [ $# -ne 2 ] && { service_usage; exit; }
		service_restore									#执行回滚模块
		service_log										#显示日志
        ;;

    backup )											#备份
        [ $# -ne 2 ] && { service_usage; exit; }
        service_backup									#备份tomcat到/home/yunwei/backup/bak${Date}/$AppName目录；
		service_log										#显示日志
        ;;

    * )
        service_usage									#使用帮助；
        ;;
esac
exit 0
