### ansible-playbook部署zabbix_agent

```
---
  - hosts: 192.168.83.131
    remote_user: root
    tasks:
      - name: install lib package
        yum: name="{{item}}" state=present
        with_items:
          - curl
          - curl-devel
          - net-snmp
          - net-snmp-devel
          - perl-DBI
          - mariadb-devel
          - mysql-devel
 
      - name: download zabbix software package
        get_url: 
          url: http://47.107.55.126:81/zabbix-4.2.5.tar.gz 
          dest: /root/
    
      - name: unzip zabbix software
        unarchive: 
          src: /root/zabbix-4.2.5.tar.gz
          dest: /root/
          copy: no

      - name: create zabbix user
        user: 
          name: "{{ item }}"
          state: present
        with_items:
          - zabbix
      
      - name: install zabbix_agent
        shell: |
          cd /root/zabbix-4.2.5
          ./configure --prefix=/usr/local/zabbix --enable-agent
          make 
          make install
          ln  -s  /usr/local/zabbix/sbin/zabbix_*  /usr/local/sbin/
          cp misc/init.d/tru64/zabbix_agentd /etc/init.d/zabbix_agentd
          chmod o+x /etc/init.d/zabbix_agentd

      - name: copy zabbix_agent configure to remote hosts
        copy: src=zabbix_agentd.conf.j2 dest=/usr/local/zabbix/etc/zabbix_agentd.conf
      
      - name: start zabbix_agent
        shell: /etc/init.d/zabbix_agentd  restart
```

