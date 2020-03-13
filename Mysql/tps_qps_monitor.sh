#!/bin/bash
Uptime=`mysqladmin --defaults-extra-file=tmp.txt status | awk '{print $2}'`
QPS() {
 Questions=`mysqladmin --defaults-extra-file=tmp.txt status | awk '{print $6}'`
 awk 'BEGIN{printf "%.2f\n",'$Questions'/'$Uptime'}'
}
#TPS
TPS() {
 rollback=`mysqladmin --defaults-extra-file=tmp.txt extended-status | awk '/\<Com_rollback\>/{print $4}'`
 commit=`mysqladmin --defaults-extra-file=tmp.txt extended-status | awk '/\<Com_commit\>/{print $4}'`
 awk 'BEGIN{printf "%.2f\n",'$(($rollback+$commit))'/'$Uptime'}'
}
$1

echou $1