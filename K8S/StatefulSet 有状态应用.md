# StatefulSet 有状态应用

```
apiVersion: apps/v1				#资源对象api版本
kind: StatefulSet				#资源对象：StatefulSet	
metadata:						#元数据信息
  name: web						#定义StatefulSet资源名称
spec:
  selector:						#标签选择器
    matchLabels:				#匹配标签， match：匹配的意思
      app: nginx				#匹配应用：nginx
  serviceName: "nginx"
  replicas: 3					#副本数：3
  template:						#模板
    metadata:					#元数据
      labels:					#标签
        app: nginx		#		标签名称，与上面的匹配标签保持一致。
    spec:
      terminationGracePeriodSeconds: 10
      containers:				#容器
      - name: nginx				#容器名称
        image: nginx			#使用的镜像
        ports:
        - containerPort: 80		#容器端口
          name: web				#名称
        volumeMounts:			#定义挂载卷
        - name: www				#挂载名称
          mountPath: /usr/share/nginx/html	#定义挂载路径
  volumeClaimTemplates:			#使用卷的模板，也就是你请求什么样的资源
  - metadata:
      name: www									#这里与上面的挂载名称对应
    spec:
      accessModes: [ "ReadWriteOnce" ]			#可读写权限
      storageClassName: "managed-nfs-storage"  #指定上面创建的 storageClassName存储类名称
      resources:
        requests:
          storage: 1Gi			#指定资源大小：1G
```