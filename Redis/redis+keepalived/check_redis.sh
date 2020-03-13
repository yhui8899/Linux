#!/bin/bash

# Source function library.
. /etc/init.d/functions

EXEC=/usr/local/bin/redis-server
CLIEXEC=/usr/local/bin/redis-cli
PIDFILE=/var/run/redis_6379.pid
REDISPORT="6379"
PASS="P@SSW0RD"
REDISPATH=/etc/redis
LOGFILE=/var/log/redis-state.log
LogDate=$(date +"%F %T")
RCMD=/etc/init.d/redis_6379

LOCALIP=192.168.0.205
REMOTEIP=192.168.0.206
VIPIP=192.168.0.200

VIPALIVE=`ip addr |grep "$VIPIP"`
if [[ "$VIPALIVE" == "" ]]; then
    if [[ "`$CLIEXEC -h $LOCALIP -a $PASS PING`" != "PONG" ]]; then
        echo "[warn]: $LogDate redis server is not health... Restart Server" >> $LOGFILE
        $RCMD restart >> $LOGFILE 2>&1
        sleep 1
        if [ "`$CLIEXEC -h $LOCALIP -a $PASS PING`" == "PONG" ]; then
            echo "$LogDate redis server restart success..." >> $LOGFILE
        else
            echo "[error]: $LogDate redis server restart fail, will be stop..." >> $LOGFILE
        fi        
    fi
else
    #check local service is running
    if [[ "`$CLIEXEC -h $LOCALIP -a $PASS PING`" == "PONG" ]]; then
        # check local redis server role.
        REDISROLE=`$CLIEXEC -h $LOCALIP -a $PASS info | grep "role"`
        if grep "role:slave" <<< $REDISROLE >/dev/null 2>&1 ; then
            #change local redis server as master 
            echo "$LogDate Run SLAVEOF NO ONE... Master Role" >> $LOGFILE
            $CLIEXEC -h $LOCALIP -a $PASS SLAVEOF NO ONE >> $LOGFILE 2>&1
 
            #change remoting redis server as slave
            REMOTEREDISROLE=`$CLIEXEC -h $REMOTEIP -a $PASS info | grep "role"`
            if grep "role:master" <<< $REMOTEREDISROLE >/dev/null 2>&1 ; then
                echo "$LogDate Run remote server SLAVEOF... $REMOTEIP Backup Role" >> $LOGFILE
                $CLIEXEC -h $REMOTEIP -a $PASS SLAVEOF $LOCALIP 6379 >> $LOGFILE 2>&1
                $CLIEXEC -h $REMOTEIP -a $PASS CONFIG SET masterauth $PASS >> $LOGFILE  2>&1
            fi
        else
            REMOTEREDISROLE=`$CLIEXEC -h $REMOTEIP -a $PASS info | grep "role"`
            if grep "role:master" <<< $REMOTEREDISROLE >/dev/null 2>&1 ; then
                echo "$LogDate Run remote server SLAVEOF... $REMOTEIP Backup Role" >> $LOGFILE
                $CLIEXEC -h $REMOTEIP -a $PASS SLAVEOF $LOCALIP 6379 >> $LOGFILE  2>&1
                $CLIEXEC -h $REMOTEIP -a $PASS CONFIG SET masterauth $PASS >> $LOGFILE  2>&1
            fi
        fi
    else
        echo "[warn]: $LogDate redis server is not health... Restart Server" >> $LOGFILE
        $RCMD restart >> $LOGFILE 2>&1
        sleep 2
        if [ "`$CLIEXEC -h $LOCALIP -a $PASS PING`" != "PONG" ]; then
            echo "[error]: $LogDate redis server will be stop..." >> $LOGFILE
            systemctl restart keepalived.service
        fi
    fi
fi
