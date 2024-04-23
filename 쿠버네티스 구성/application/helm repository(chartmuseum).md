# 1. Helm repository 구성

## 1. helm chartmuseum 파일 및 설정 변경

- Docs: https://chartmuseum.com/docs/#configuration

```
  mkdir helm-repo
  kubectl create ns helm-repo
  helm repo add chartmuseum https://chartmuseum.github.io/charts
  helm repo update
  helm show values  chartmuseum/chartmuseum > chartmuseum-values.yaml
```

```
---
env:
  open:
    STORAGE: local
  secret:
    BASIC_AUTH_USER: curator
    BASIC_AUTH_PASS: mypassword
persistence:
  enabled: true
  accessMode: ReadWriteOnce
  size: 8Gi
  storageClass: "nfs-client"
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
  hosts:
    - name: chartrepo.company.com
      path: /
      tls: false
    - name: chartrepo.company.com
      path: /
      tls: true
      tlsSecret: chartrepo-tls
  ingressClassName: nginx
---

```

## 2. tls key 생성

```
--- root 용 ----
openssl genrsa -out tls.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=KO/ST=Han/OU=Personal/CN=chartrepo.company.com" \
 -key tls.key \
 -out tls.crt

 --- domain용 ---
openssl genrsa -out chartrepo.company.com.key 4096
# csr 생성
openssl req -sha512 -new \
 -subj "/C=KO/ST=Uk/L=Cheonan/O=company/OU=Personal/CN=chartrepo.company.com" \
    -key chartrepo.company.com.key \
    -out chartrepo.company.com.csr
--- x509 v3 extension 파일생성
cat > v3.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=chartrepo.company.com
DNS.2=chartrepo.company
EOF
--- v3.ext 파일로 certificate를 생성
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA tls.crt -CAkey tls.key -CAcreateserial \
    -in chartrepo.company.com.csr \
    -out chartrepo.company.com.crt

kubectl create secret tls tls-secret -n helm-repo \
--key=chartrepo.company.com.key \
--cert=chartrepo.company.com.crt
```

## 3. 설치 및 확인

```
 helm install -n helm-repo chartmuseum chartmuseum/chartmuseum  -f chartmuseum-values.yaml

----
 /etc/hosts(C:\Windows\System32\drivers\etc\hosts) 등록
 12.xxx.xxx.xx chartrepo.company.com
---
chartrepo.company.com 접속 후 설정한 BASIC ID, PASSWORD 입력후 NGINX기본화면 뜨면 완료
```

## 4. chart repository 추가

```
helm repo add chartrepo https://chartrepo.company.com --ca-file ~/k8s/helm-repo/cert/chartrepo.company.com.crt --username sysadm --password adm01sys!

helm repo list
```

## 5. package와 repo 등록

```
helm package harbor
helm push harbor-0.1.0.tgz chartrepo --ca-file ~/chartrepo.company.com.crt -f
helm repo update
helm search harbor

-- 설치
helm install chartrepo/harbor --name harbor -n harbor
```
