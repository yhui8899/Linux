# Job任务

**job分为两种：**

- **job普通任务**：一次性执行；

- **cronjob定时任务**：有计划的执行；

  **应用场景**：job比较适用一些离线数据处理，视频解码等业务,适合一些临时任务；

### job普通任务：

vim job.yaml

```shell
apiVersion: batch/v1		#job的api版本
kind: Job					#资源对象
metadata:					#元数据信息
  name: pi					#定义元数据信息的名称，也就是job的名称
spec:
  template:					#被管理对象，也就是容器
    spec:
      containers:			#容器
      - name: pi			#容器名称
        image: perl			#镜像
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"] 	#job任务执行的命令
      restartPolicy: Never		#重启策略，Never是不重启，任务执行成功的情况下不会重启；
  backoffLimit: 4				#设置任务重试的次数，如果任务失败将会按照这个次数来重试；
```

**执行创建job：**

```shell
kubectl apply -f job.yaml
```

**查看job状态：**

```shell
[root@k8s-master test]# kubectl get job
NAME               COMPLETIONS   DURATION   AGE
pi                 1/1           4m14s      32m

#查看job容器：
[root@k8s-master test]# kubectl get pod |grep pi
pi-4cwk7                                  0/1     Completed   0          34m
```

官方文档：https://kubernetes.io/docs/concepts/workloads/controllers/job/

--------------

### cronjob 定时任务：

contjob定时任务和linux的crontab定时任务一样，使用场景：通知，备份等；

vim cronjob.yaml

```shell
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"				#时间表达式，与linux的crontab一样
  jobTemplate:							#job模板，定义容器执行的定时任务相关
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            imagePullPolicy: IfNotPresent		#镜像拉取策略，IfNotPresent只有当本地没有的时候才下载镜像，默认使用该策略
            args:			#参数
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster	#cronjob任务执行的命令
          restartPolicy: OnFailure		#重启策略，当容器异常退出（退出状态码非0）时，才重启容器。
```

**执行创建cronjob**

```shell
 kubectl apply -f cronjob.yaml
```

**查看cronjob**

```shell
[root@k8s-master test]# kubectl get cronjob
NAME    SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
hello   */1 * * * *   False     0        15s             31s
```

**查看容器和任务：**

```shell
[root@k8s-master test]# kubectl get pod
NAME                                      READY   STATUS      RESTARTS   AGE
hello-1614587700-4thlp                    0/1     Completed   0          2m41s
hello-1614587760-lwxjw                    0/1     Completed   0          101s
hello-1614587820-4m6w2                    0/1     Completed   0          41s

#查看任务执行是否成功
[root@k8s-master test]# kubectl logs hello-1614587700-4thlp
Mon Mar  1 08:35:01 UTC 2021			#打印出当前时间
Hello from the Kubernetes cluster		#看到已经有执行echo输出内容了，证明执行成功！
[root@k8s-master test]#
```

官方文档：https://kubernetes.io/zh/docs/tasks/job/automated-tasks-with-cron-jobs/

