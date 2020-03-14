#!/bin/bash
info=$(curl -s -i -u admin:admin "http://localhost:15672/api/queues" | sed 's/messages_details/\\n/g')
info=$(echo -e "$info" | grep -v spring | grep name)
name=$(echo -e "$info" | grep -Po name.*message_bytes_paged_out | cut -f3 -d '"')
messages_ready=$(echo -e "$info" | grep -Po messages_ready.*reductions_details | cut -f6 -d '"' | cut -f2 -d ':' | cut -f1 -d ',')
messages_unack=$(echo -e "$info" | grep -Po messages_unacknowledged\":.*messages_ready_details | cut -f2 -d ':' | cut -f1 -d ',')
messages_total=$(echo -e "$info" | grep -Po messages\":.*messages_unacknowledged_details | cut -f2 -d ':' | cut -f1 -d ',')
host=$(echo -e "$info" | grep -Po rabbit@mq.*arguments | cut -f1 -d '"')
for Dname in $name; do
    sleep 1
    hs=$(echo -e "$name" | grep -n ^$Dname$ | cut -f1 -d ':')
    hz=$(echo -e "$messages_ready" | sed -n "${hs}p")
    if [ $hz -gt 100000 ]; then
        echo "
报警主机:192.168.1.14 \n
报警时间: $(date) \n
报警信息:$Dname messages_ready 值大于100000 \n
当前状态:$hz
        " >/opt/sh/$Dname.log
        wx_rr=$(cat /opt/sh/$Dname.log)
        sh /opt/sh/weixin.sh 'lijingfeng|jieyingqiu' '192.168.1.14_mq报警' "$wx_rr"
    else
        if [ -e /opt/sh/$Dname.log ]; then
            echo "
恢复主机:192.168.1.14 \n
恢复时间: $(date) \n
恢复信息:$Dname messages_ready 值小于100000 \n
当前状态:$hz
            " >/opt/sh/$Dname.log
            wx_rr=$(cat /opt/sh/$Dname.log)
            rm -rf /opt/sh/$Dname.log
            sh /opt/sh/weixin.sh 'lijingfeng|jieyingqiu' '192.168.1.14_mq恢复' "$wx_rr"
        fi
    fi
done
