#!/bin/bash

#定义项目名, 先使用root用户创建备份目录
#tname=$1
backlog="/home/yunwei/halog"
logfile="/var/log/haproxy.log"
d=`date +%Y%m%d`

if [ ! -d $backlog ]; then
   mkdir -p $backlog
fi

\cp -pa $logfile $backlog/haproxy.log.${d}
echo "" > $logfile

find $backlog -name "*.log.*" -type f -mtime +15 | xargs rm -rf
