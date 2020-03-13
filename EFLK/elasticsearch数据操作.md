# elasticsearch数据操作

##### RestFul API格式

```
如：curl -X<verb> ‘<protocol>://<host>:<port>/<path>?<query_string>’-d ‘<body>’
```

| **参数**     | **描述**                                              |
| ------------ | ----------------------------------------------------- |
| verb         | HTTP方法，比如GET、POST、PUT、HEAD、DELETE            |
| host         | ES集群中的任意节点主机名                              |
| port         | ES HTTP服务端口，默认9200                             |
| path         | 索引路径                                              |
| query_string | 可选的查询请求参数。例如?pretty参数将返回JSON格式数据 |

```
查看索引：
curl http://192.168.83.129:9200/_cat/indices?v   
新建索引：
curl -X PUT 192.168.83.129:9200/logs-test-2020-02-28  #索引名称是：logs-test-2020-02-28
删除索引：
curl -X DELETE 192.168.83.129:9200/logs-test-2020-02-28
```

##### 创建索引：

```
curl http://192.168.83.129:9200/_cat/indices?v  
```

##### 由于我们新创建的索引没有数据，所以接下来去创建数据，具体如下：

```
curl -X PUT "192.168.83.129:9200/logs-test-2020-02-28/_doc/1?pretty" -H 'Content-Type: application/json' -d' { "name": "xiaofeige"}'
#回车后会返回一个json格式的结果：
{
  "_index" : "logs-test-2020-02-28",
  "_type" : "_doc",
  "_id" : "1",
  "_version" : 1,
  "result" : "created",
  "_shards" : {
    "total" : 2,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 1,
  "_primary_term" : 1
}
-----------------------------------------------------------------------------
#注解：
logs-test-2020-02-28：	#索引名称；
_doc：	#操作文档
i?pretty：	#文档的ID
-H 'Content-Type: application/json' ： #格式，指定头类型是Jason格式的，否则识别不了类型；
{ "name": "xiaofeige"} ：#指定的内容
```

##### 查看刚刚创建的索引字段内容：

curl -X GET "192.168.83.129:9200/logs-test-2020-02-28/_doc/1?pretty"

```
{
  "_index" : "logs-test-2020-02-28",
  "_type" : "_doc",
  "_id" : "1",
  "_version" : 1,
  "found" : true,
  "_source" : {
    "name" : "xiaofeige"
  }
}
```

##### 修改索引数据内容：

##### 使用POST来修改，或者直接在创建数据的那条命令上面做修改也可以；

```
curl -X POST "192.168.83.129:9200/logs-test-2020-02-28/_doc/1?pretty" -H 'Content-Type: application/json' -d' { "name": "guangzhou-xiaofeige"}'
```

##### 修改成功返回的结果：

```
{
  "_index" : "logs-test-2020-02-28",
  "_type" : "_doc",
  "_id" : "1",
  "_version" : 2,
  "result" : "updated",
  "_shards" : {
    "total" : 2,
    "successful" : 2,
    "failed" : 0
  },
  "_seq_no" : 4,
  "_primary_term" : 1
}
```

##### 新增字段数据：

```
curl -X POST "192.168.83.129:9200/logs-test-2020-02-28/_doc/1?pretty" -H 'Content-Type: application/json' -d' { "name": "guangzhou-xiaofeige","age": 25}'
```



##### 再来查看刚刚修改的索引内容：

```
[root@localhost logs]# curl -X GET "192.168.83.129:9200/logs-test-2020-02-28/_doc/1?pretty"                                                      {
  "_index" : "logs-test-2020-02-28",
  "_type" : "_doc",
  "_id" : "1",
  "_version" : 2,
  "found" : true,
  "_source" : {
    "name" : "guangzhou-xiaofeige"
  }
}
```



##### 删除刚刚创建的索引：

```
curl -X DELETE "192.168.83.129:9200/logs-test-2020-02-28/_doc/1?pretty"
```



##### 删除之后在来查看就看不到了，返回下面的结果：

```
[root@localhost logs]# curl -X GET "192.168.83.129:9200/logs-test-2020-02-28/_doc/1?pretty"   
{
  "_index" : "logs-test-2020-02-28",
  "_type" : "_doc",
  "_id" : "1",
  "found" : false
}
```

官方帮助文档：https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html

导入数据到elasticsearch：

```
导入数据：
curl -H "Content-Type: application/json" -XPOST "192.168.83.129:9200/bank/_doc/_bulk?pretty&refresh" --data-binary "@accounts.json"

查看一下是否导入成功：
curl "192.168.83.129:9200/_cat/indices?v"

查询一下数据：
curl -X GET "192.168.83.129:9200/bank/_search?q=*&sort=account_number:asc&pretty"
#bank是数据库
_searchq=* 		#ES批量索引中的所有文档
sort=account_number:asc 	#表示根据account_number按升序对结果排序
以上方式是使用查询字符串替换请求主体。
```

##### elasticsearch查询：

```
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": { "match_all": {} },
  "sort": [
    { "account_number": "asc" }
  ]
}
'
#这个区别在于不是传入的q=* URI,而是向_search API提供JSON格式的查询请求体。
```

### match_all：匹配所有文档。默认查询

```
#查询所有，默认只返回10个文档
curl -X GET "localhost:9200/bank/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": { "match_all": {} }
}
'
#query告诉我们查询什么，match_all使我们查询的类型。match_all查询仅仅在指定的索引的所有文件进行搜索。
```

### from，size

除了query参数外，还可以传递其他参数影响查询结果，比如上面的sort，下面的size：

```
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": { "match_all": {} },
  "size": 1
}

注意：size未指定，默认为10
```

```
#定义一个查询范围
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": { "match_all": {} },
  "from": 10,
  "size": 10
}
'
#此功能实现分页功能非常有用。如果from未指定，默认为0
```



##### 返回_source字段中的几个字段：

```
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": { "match_all": {} },
  "_source": ["account_number", "balance"]
}
'
```



### **match**

基本搜索查询，针对特定字段或字段集合进行搜索

```
#查询编号为20的账户：
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": { "match": { "account_number": 20 } }
}
```



```
#返回地址中包含mill的账户：
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": { "match": { "address": "mill" } }
}
'
#返回地址有包含mill或lane的所有账户：
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": { "match": { "address": "mill lane" } }
}
'
```

### bool

```
查询包含mill和lane的所有账户：
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "bool": {
      "must": [
        { "match": { "address": "mill" } },
        { "match": { "address": "lane" } }
      ]
    }
  }
}
'
#该bool must指定了所所有必须为真才匹配。

---------------------------------------------------
查询包含mill或lane的所有账户：
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "bool": {
      "should": [
        { "match": { "address": "mill" } },
        { "match": { "address": "lane" } }
      ]
    }
  }
}
'

```

### range

renge：指定区间内的数字或者时间。

操作符：gt大于，gte大于等于，lt小于，lte小于等于

```
#查询余额大于或等于20000且小于等于30000的账户：
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "bool": {
      "must": { "match_all": {} },
      "filter": {
        "range": {
          "balance": {
            "gte": 20000,
            "lte": 30000
                      }
        }
      }
    }
  }
}
'
```

------

