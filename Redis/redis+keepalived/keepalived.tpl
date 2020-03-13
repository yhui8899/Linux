! Configuration File for keepalived
global_defs {
    router_id RID_NUMBER
}
vrrp_script check_redis {
    script "/etc/keepalived/check_redis.sh"
    interval 2
#    weight -5
    fall 3
    rise 2
}
vrrp_instance VI_1 {
    state CHANGE_ROLE
    interface CHANGE_NETID
    unicast_src_ip CHANGE_LOCAL_IP
    virtual_router_id CHANGE_VRID
    priority PRIO_ID
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass P@SSW0RD
    }
    unicast_peer { 
        CHANGE_REMOTE_IP
    }
    virtual_ipaddress {
        CHANGE_VIP_IP
    }
    track_script {
       check_redis
    }
}
