# 1. Argo CD 구성

## 1. Argo 구성 및 config file 설정

```
k create ns cicd

cat << EOF > config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: docker-config
  namespace: ci
data:
  daemon.json: |
    {k get
      "insecure-registries": ["harbor.steco.com"]
    }
EOF
k apply -f config.yaml
```

## 2. pv, pvc 설정

- pv

```
cat << EOF > pv-jenkins.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: standard
  name: pv-jenkins
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 50Gi
  nfs:
    path: /data/jenkins
    server: 10.10.123.16
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: standard
  name: pv-jenkins-log
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: 1Gi
  nfs:
    path: /data/jenkins
    server: 10.10.123.16
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
EOF
```

- pvc

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app: jenkins
  name: jenkins-pvc
  namespace: cicd
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app: jenkins
  name: jenkins-log-pvc
  namespace: cicd
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```

## 3. svc 및 deploy 설정

- svc yaml

```
apiVersion: v1
kind: Service
metadata:
  name: jenkins-service
  namespace: cicd
  labels:
    app: jenkins
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
    name: http
  - port: 443
    protocol: TCP
    targetPort: 8080
    name: https
  selector:
    app: jenkins

---
apiVersion: v1
kind: Service
metadata:
  name: jenkins-service-jnlp
  namespace: cicd
  labels:
    app: jenkins
spec:
  ports:
  - port: 50000
    protocol: TCP
    targetPort: 50000
    name: jnlp
  selector:
    app: jenkins

```

- deploy yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins-deployment
  namespace: cicd
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  revisionHistoryLimit: 10
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: jenkins
    spec:
      containers:
      - image: harbor.steco.com/cicd/jenkins:latest
        imagePullPolicy: IfNotPresent
        name: jenkins
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        - containerPort: 50000
          name: jnlp
          protocol: TCP
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /var/jenkins_home
          name: jenkins-vol
        - mountPath: /var/run
          name: shared
        - mountPath: /var/logs
          name: jenkins-log
      - image: harbor.steco.com/cicd/docker:dind
        imagePullPolicy: IfNotPresent
        name: docker
        securityContext:
          privileged: true
        volumeMounts:
        - mountPath: /var/run
          name: shared
        - mountPath: /etc/docker
          name: docker-config
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        runAsUser: 0
      terminationGracePeriodSeconds: 30
      volumes:
      - name: jenkins-vol
        persistentVolumeClaim:
          claimName: jenkins-pvc
      - hostPath:
          path: /usr/share/zoneinfo/Asia/Seoul
          type: ""
        name: timezone-seoul
      - name: jenkins-log
        persistentVolumeClaim:
          claimName: jenkins-log-pvc
      - name: shared
        emptyDir: {}
      - name: docker-config
        configMap:
          name: docker-config
```

- 폐쇄망 환경에서 install 방법

  - 외부망 통신이 가능한 환경에서 Jenkins와 plugin 설치 -> /var/jenkins_home/plugins의 plugin 추출 -> 폐쇄망 환경 jenkins directory에 mount

- 초기 Administrator passowrd

```
kubectl exec -n cicd pod/jenkins-deployment-6cb5d49979-spdc7 -- cat /var/jenkins_home/secrets/initialAdminPassword
```

-
