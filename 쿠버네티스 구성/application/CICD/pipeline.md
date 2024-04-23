# 1. 파이프라인 구성

## 1. Jenkins를 통한 CI 파이프라인

```
pipeline {
    agent any
    options {
        timeout(time: 1, unit: 'HOURS')
    }
    environment {
        SOURCECODE_JENKINS_CREDENTIAL_ID = credentials('jaeuk')
        SOURCE_CODE_URL = 'https://gitlab.company.com/infra/test.git'
        RELEASE_BRANCH = 'release-client'
		HARBOR_ID = credentials('harborId')
        HARBOR_PW = credentials('harborPassword')
    }
    stages {
		 stage('Git Config Setting') {
            steps {
                sh 'git config --global http.sslVerify false'
            }
        }

        stage('Clone') {
            steps {
                git url: "$SOURCE_CODE_URL",
                    branch: "$RELEASE_BRANCH",
                    credentialsId: "$SOURCECODE_JENKINS_CREDENTIAL_ID"
                sh "ls -al"
            }
        }

        stage('Gradle Build') {

            steps {
					sh '''
					chmod 755 gradlew
                    ./gradlew clean bootjar
                    mv build/libs/*.jar app.jar
					ls -al
					''''
                }
            }
        }

        stage('Build Image') {
            steps {
                sh '''
                    docker build -t harbor.company.com/infra/test:"${VERSION}" .
                    docker login harbor.company.com -u $HARBOR_ID -p $HARBOR_PW
                    docker push harbor.company.com/infra/test:"${VERSION}"
                '''
            }
        }
         stage('Invoke Argo Pipeline') {
            steps {
                build job: 'argo-deploy', parameters: [
                    string(name: 'VERSION', value: "${params.VERSION}")
                    ]
            }
        }
}
```

- Docker Socker 설정
  - unix:///var/run/docker.sock

## 2. Argo를통한 CD

### 2-1. Argo를 위한 pipeline

```
pipeline {
    agent any
       environment {
        gitlab-id = credentials('gitlabUk')
    }
    stages {
        stage('Git Config Setting') {
            steps {
                sh '''
                git config --global http.sslVerify false
                git config --global user.name "k23981070"
                git config --global user.email "jaeuk730@company.com"
                git config --global credential.helper store
                '''
            }
        }
        stage('Argo Git Clone') {
            steps {
                git branch: 'main', credentialsId: 'gitlab-id', url: 'https://gitlab.company.com/root/board-deploy.git'
                sh '''
                    rm -rf board-app-deployment.yaml
                    sed "s/VERSIONTAG/"${VERSION}"/g" "board-app-deployment-template.yaml" > board-app-deployment.yaml
                    ls -al
                    git add --all
                    git commit -m 'update image tag'
                    git push origin main
                '''
            }
        }
    }
}
```

### 2-2. Argo yaml

```
## board-app-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: board
  name: board
  namespace: board-deploy
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: board
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: board
    spec:
      containers:
      - image: harbor.company.com/infra/test:v0.0.1
        imagePullPolicy: IfNotPresent
        name: board
        ports:
        - containerPort: 8080
          protocol: TCP
        resources: {}
        securityContext:
          runAsUser: 0
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
```

- ArgoCD에서 application Auto Sync 설정시 자동 Cluster에 반영
