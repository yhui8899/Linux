node ("slave-136") {
	stage('git checkout'){
		checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'git@192.168.83.135:/home/git/repos/sharek.git']]])
	}
	stage ('Manven Build'){
		sh '''
		export JAVA_HOME=/usr/local/java
		/usr/local/maven/bin/mvn clean package -Dmaven.test.skip=true
		'''
	}
	stage ('Build and Push Image'){
sh ''' 
REPOSITORY=192.168.83.144/docker-java/shareku:${tag}
cat >Dockerfile << EOF
FROM 192.168.83.144/docker-java/tomcat:v1
RUN  rm -rf /usr/local/tomcat/webapps/ROOT
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war
CMD ["catalina.sh","run"]
EOF
docker build -t ${REPOSITORY} -f Dockerfile .
docker login -u xiaofeige -p Yhui8899 192.168.83.144
docker push ${REPOSITORY}
'''
	}
	stage ('Deploy to Docker'){
		sh '''
		REPOSITORY=192.168.83.144/docker-java/shareku:${tag}
		docker rm -f shareku |true
		docker image rm ${REPOSITORY} |true
		docker login -u xiaofeige -p Yhui8899 192.168.83.144
		docker container run -d --name shareku -v /usr/local/jdk:/usr/local/jdk -p 88:8080 ${REPOSITORY}
		'''
	}
}