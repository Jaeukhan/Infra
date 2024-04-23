# 1. gitlab 구성

## 1. pv생성

## 1. helm chart 주입

```
helm repo add gitlab https://charts.gitlab.io/
helm repo update

mkdir gitlab
cd gitlab

#repo 내용확인
helm search repo gitlab

helm show values gitlab/gitlab > gitlab-values.yaml

#네임스페이스 생성
kubectl create ns gitlab
```

## 2. pv 생성

```
cat << EOF > pv-gitlab.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: standard
  name: pv-01-gitlab
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 50Gi
  nfs:
    path: /data/gitlab
    server: 12.xxx.xxx.16
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: standard
  name: pv-02-gitlab
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 50Gi
  nfs:
    path: /data/gitlab
    server: 12.xxx.xxx.16
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: standard
  name: pv-03-gitlab
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 50Gi
  nfs:
    path: /data/gitlab
    server: 12.xxx.xxx.16
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: standard
  name: pv-04-gitlab
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 50Gi
  nfs:
    path: /data/gitlab
    server: 12.xxx.xxx.16
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: standard
  name: pv-05-gitlab
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 50Gi
  nfs:
    path: /data/gitlab
    server: 12.xxx.xxx.16
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem

EOF
kubectl apply -f pv-gitlab.yaml
```

## 3. tls를 위한 secret 생성

```
--- root 용 ----
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=KO/ST=Han/OU=Personal/CN=gitlab.company.com" \
 -key ca.key \
 -out gitlab.company.ca.crt
--- domain용 ---
openssl genrsa -out tls.key 4096
# csr 생성
openssl req -sha512 -new \
 -subj "/C=KO/ST=Uk/L=Cheonan/O=company/OU=Personal/CN=gitlab.company.com" \
    -key tls.key \
    -out tls.csr
--- x509 v3 extension 파일생성
cat > v3.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=gitlab.company.com
DNS.2=gitlab.company
EOF
--- v3.ext 파일로 certificate를 생성
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA gitlab.company.ca.crt -CAkey ca.key -CAcreateserial \
    -in tls.csr \
    -out tls.crt
```

- secret을 통한 tls 설정

```
kubectl create secret tls gitlab-tls -n gitlab \
--cert=tls.crt \
--key=tls.key
```

## 4. yaml 설정별경 및 설치

- 설정 변경

```
global.edition: ce
global.hosts : domain, gitlab, minio, registry, externalIP
ingress.configureCertmanager: false
ingress.class: nginx
ingress.tls.secretName: gitlab-tls
certmanager.install: false
prometheus.install :false
nginx-ingress.enabled: false
gilab-runner.install: false
```

- 설치

```
helm install gitlab gitlab/gitlab -n gitlab -f gitlab-values.yaml
helm upgrade gitlab gitlab/gitlab -n gitlab -f gitlab-values.yaml
```

- 초기 비밀번호 확인

```
# id: root
kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d ; echo
```
