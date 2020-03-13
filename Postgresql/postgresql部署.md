## 																			postgresql部署：

#### 下载postgresql-11.0

```
wget https://ftp.postgresql.org/pub/source/v11.0/postgresql-11.0.tar.gz
```

#### 安装依赖：

```
yum install -y perl-ExtUtils-Embed readline-devel zlib-devel pam-devel libxml2-devel libxslt-devel openldap-devel  python-devel gcc-c++ openssl-devel cmake
```

#### 解压和安装：postgresql-11.0.tar.gz

```
tar -xf postgresql-11.0.tar.gz
cd  postgresql-11.0/

./configure --prefix=/usr/local/pgsql-11.0  --with-blocksize=8 --with-wal-blocksize=8 --with-segsize=1 --with-pgport=5432 --with-libedit-preferred --with-perl --with-openssl --with-libxml  --with-libxslt --enable-thread-safety --enable-nls=en_US.UTF-8

make
make install
```

#### 创建postgresql用户，数据目录

```
useradd postgres
mkdir -p /pgdata/{data,logs}
chown postgres.postgres -R /pgdata/
```

#### 设置环境变量

```
ln -sf /usr/local/pgsql11.0/  /usr/local/pgsql
# 创建连接文件，方便后期的升级
```

##### 将如下信息添加到环境变量中

```
#全局环境变量，
vim /etc/profile
export PGDATA=/pgdata/data
export PGHOME=/usr/local/pgsql-11.0
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PGHOME/lib
export PATH=$PATH:$PGHOME/bin/

#也可以将如上代码添加到：vim .bash_profile 用户环境变量中，需要先：su - postgres；
```

#### 5.安装扩展

```
export PATH=$PATH:/usr/local/pgsql/bin/
cd  postgresql-11.0/contrib		#进到源码目录中的contrib目录
make all
```

##### 初始化pgsql

su - postgres

initdb

或者：su - postgres -c "initdb"

##### 看到如下信息表示初始化成功：

```
[postgres@localhost ~]$ initdb            
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /pgdata/data ... ok
creating subdirectories ... ok
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting dynamic shared memory implementation ... posix
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

WARNING: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:
	pg_ctl -D /pgdata/data -l logfile start
```

##### 进入pgdata目录查看下数据目录：

```
cd /pgdata/data
drwx------ 5 postgres postgres    41 Feb  4 03:59 base
drwx------ 2 postgres postgres  4096 Feb  4 03:59 global
drwx------ 2 postgres postgres     6 Feb  4 03:59 pg_commit_ts
drwx------ 2 postgres postgres     6 Feb  4 03:59 pg_dynshmem
-rw------- 1 postgres postgres  4513 Feb  4 03:59 pg_hba.conf
-rw------- 1 postgres postgres  1636 Feb  4 03:59 pg_ident.conf
drwx------ 4 postgres postgres    68 Feb  4 04:08 pg_logical
drwx------ 4 postgres postgres    36 Feb  4 03:59 pg_multixact
drwx------ 2 postgres postgres    18 Feb  4 04:03 pg_notify
drwx------ 2 postgres postgres     6 Feb  4 03:59 pg_replslot
drwx------ 2 postgres postgres     6 Feb  4 03:59 pg_serial
drwx------ 2 postgres postgres     6 Feb  4 03:59 pg_snapshots
drwx------ 2 postgres postgres     6 Feb  4 03:59 pg_stat
drwx------ 2 postgres postgres    25 Feb  4 04:10 pg_stat_tmp
drwx------ 2 postgres postgres    18 Feb  4 03:59 pg_subtrans
drwx------ 2 postgres postgres     6 Feb  4 03:59 pg_tblspc
drwx------ 2 postgres postgres     6 Feb  4 03:59 pg_twophase
-rw------- 1 postgres postgres     3 Feb  4 03:59 PG_VERSION
drwx------ 3 postgres postgres    60 Feb  4 03:59 pg_wal
drwx------ 2 postgres postgres    18 Feb  4 03:59 pg_xact
-rw------- 1 postgres postgres    88 Feb  4 03:59 postgresql.auto.conf
-rw------- 1 postgres postgres 23799 Feb  4 03:59 postgresql.conf
-rw------- 1 postgres postgres    55 Feb  4 04:03 postmaster.opts
-rw------- 1 postgres postgres    79 Feb  4 04:03 postmaster.pid
数据目录介绍：
base目录是表空间目录，
global目录是相关全局变量目录,
pg_hba.conf是访问控制配置文件，
postgresql.conf是postgresql主配置文件。
修改配置文件：postgresql.conf

#listen_addresses = 'localhost'改为：listen_addresses = '*'
```

#### 启动数据库：

```
启动方式：pg_ctl -D /pgdata/data -l logfile start

pg_ctl -D /pgdata/data -l /pgdata/logs/server.log start
或者：
su - postgres -c "pg_ctl -D /pgdata/data -l /pgdata/logs/server.log start"
停止数据库：
pg_ctl -D /pgdata/data -l /pgdata/logs/server.log stop
或者：
su - postgres -c "pg_ctl -D /pgdata/data -l /pgdata/logs/server.log stop"
```

#### 登录数据库

```
psql -h 127.0.0.1 -d postgres -U postgres -p 5432 

命令提示符前面的就是当前的数据库，使用 \l 查看当前的数据库列表
\l ： 查看所有库
创建一个test库：
CREATE DATABASE test WITH OWNER=postgres ENCODING='UTF-8';
创建一个简单的表：
CREATE TABLE student (
  id integer NOT NULL,
  name character(32),
  number char(5),
  CONSTRAINT student_pkey PRIMARY KEY (id)
);
创建表之后可以使用： \d student; 查看表的详细信息
插入一条测试数据： INSERT INTO student (id, name, number) VALUES (1, '张三', '1023'); 
可以查询这条数据： SELECT * FROM student WHERE id=1; 
最后可以执行： \q 退出交互式界面
```

参考1：https://www.cnblogs.com/monkey6/p/10529439.html
参考2：https://blog.csdn.net/Linjingke32/article/details/80393576
参考3：https://blog.csdn.net/Prison_/article/details/88919611

