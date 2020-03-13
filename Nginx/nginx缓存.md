# nginx缓存配置

#### 建立一个缓存区，即缓存目录：

```
nginx缓存服务器IP：192.168.83.129

后端服务器IP：192.168.83.130-131
```

##### 首先创建缓存目录：

mkdir -p /data/cdn_cache/

#### 需要设置两部分：

#### 1、设置缓存配置，创建缓存区域

vim  proxy.conf

```
#创建缓存区域
proxy_temp_path /data/cdn_cache/proxy_temp_dir;
proxy_cache_path /data/cdn_cache/proxy_cache_dir levels=1:2 keys_zone=cache_one:50m inactive=1d max_size=1g;
proxy_connect_timeout 5;
proxy_read_timeout 60;
proxy_send_timeout 5;
proxy_buffer_size 16k;
proxy_buffers 4 64k;
proxy_busy_buffers_size 128k;
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_404;
```

##### 设置缓存配置详解如下：

```
proxy_temp_path /data/cdn_cache/proxy_temp_dir;  #缓存临时目录，缓存就是先写到这里；重命名后会写到下面的目录里；

proxy_cache_path /data/cdn_cache/proxy_cache_dir levels=1:2 keys_zone=cache_one:50m inactive=1d max_size=1g;    #缓存存放位置，从上面那个临时目录里转存过来的，		keys_zone=cache_one：这里是设置的缓存区域叫：cache_one，内存的缓存是50m，inactive=1d：表示自动清理1天没有访问的数据，max_size=1g：最大的缓存大小1g;

proxy_connect_timeout 5; 
proxy_read_timeout 60;
proxy_send_timeout 5;
proxy_buffer_size 16k;
proxy_buffers 4 64k;
proxy_busy_buffers_size 128k;
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_404;
#这里只的是故障转移，如果后端返回状态码为：500、502、503、404的时候可以把它请求到upstream负载均衡中的另外一台机器，来实现故障转移
```



#### 2、设置虚拟主机缓存配置，哪些需要缓存，哪些需要回源，配置location匹配；

```
#创建负载均衡池
upstream proxy {

        server 192.168.83.130:80 weight=10 max_fails=3;
        server 192.168.83.131:80 weight=10 max_fails=3;
}

#配置虚拟主机和缓存
server {
    listen 88;
    server_name 192.168.83.129;
    access_log /var/log/nginx/test_proxy_cache_access.log main;

    location ~ .*\.(gif|jpg|png|html|htm|css|js|ico|swf|pdf)$ #将这些静态文件缓存，剩下的都回源
 {


        proxy_redirect off;
        proxy_next_upstream http_502 http_504 http_404 error timeout invalid_header;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://proxy;

        proxy_cache cache_one;  #cache_one 是缓存区域的名称，与应上面proxy_cache_path一致即可；
        proxy_cache_key "$host$request_uri";
        add_header Cache "$upstream_cache_status";
        proxy_cache_valid 200 304 301 302 8h;
        proxy_cache_valid 404 1m;
        #proxy_cache_valid and 2d;
    }

   location / {				#动态文件回源

        proxy_redirect off;
        proxy_next_upstream http_502 http_504 http_404 error timeout invalid_header;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://proxy;

        #Use proxy Cache
        client_max_body_size 10m;
        client_body_buffer_size 128k;
        proxy_connect_timeout 90;
        proxy_send_timeout 90;
        proxy_read_timeout 90;
        proxy_buffer_size 64k;
        proxy_buffers 4 32k;
        proxy_busy_buffers_size 64k;
```

使用浏览器访问：http://192.168.83.129:88

```
[root@localhost /]# tree /data/
/data/
└── cdn_cache
    ├── proxy_cache_dir
    │   ├── 1
    │   │   └── 78
    │   │       └── 70ff3beb9538be4e7d9b244fe47f6781
    │   └── d
    │       ├── 84
    │       │   └── 3d71004d5aa4ce1e9ecbf704176f484d
    │       └── d8
    │           └── 65f3a6cac78ffa82d6833fa8ea7d6d8d
    └── proxy_temp_dir

8 directories, 3 files

#如上是缓存的目录和ID，说明缓存成功；
```

