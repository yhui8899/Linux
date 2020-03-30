#!/bin/bash
# auto install gitlab
#
# version: 11.9.4
#
# author by xiaofeige
#
# 2020年3月18日19:19:26
############################

set -e 

LIB_PACK=(curl policycoreutils openssh-server openssh-clients postfix policycoreutils-python)

gitlab_ver="11.9.4"

gitlab_soft="gitlab-ce-${gitlab_ver}-ce.0.el7.x86_64.rpm"

gitlab_url="https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/${gitlab_soft}"

yum install ${LIB_PACK[@]} -y >>/dev/null 2>&1


if [[ `ps -ef|grep -Ev "grep|$0"|grep -c gitlab` != "0" ]];then

	echo -e "\033[33mPlease uninstall gitlab Retry\033[0m"

	exit 0

elif [[ ! -f ${gitlab_soft} ]];then

	wget ${gitlab_url}
fi

rpm -ivh ${gitlab_soft}

gitlab-ctl  reconfigure

host_ip=`ip addr|grep global|awk '{print $2}'|cut -f 1 -d /`

sed -i s'/host: gitlab.example.com/host: ${host_ip}/' /var/opt/gitlab/gitlab-rails/etc/gitlab.yml

gitlab-ctl restart

sleep 10

echo -e "\033[32m使用浏览器访问:http://${host_ip}\033[0m"

exit
