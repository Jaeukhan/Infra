# 1. harbor(private image 저장소) 구성

## 0. ingress 설치 필요

-tls key로 하버 설치
https://cbwstar.tistory.com/entry/%EC%BF%A0%EB%B2%84%EB%84%A4%ED%8B%B0%EC%8A%A4-Harbor%ED%95%98%EB%B2%84-%EC%84%A4%EC%B9%98%ED%95%98%EA%B8%B0

- nginx ingress + metalLB

### 1. metalLB 설치 및 구성

- kube proxy 설정 수정

```
kubectl edit configmap -n kube-system kube-proxy
===
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true
```

```
# https://metallb.universe.tf/installation/
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.4/config/manifests/metallb-native.yaml
kubectl get ns
```

- metallb secret 생성

```
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
```

- metalLB configmap생성(ip대역 설정, 미설정 시 nginx-ingress pending 상태 유지 될수도)

```
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 10.10.130.161-10.10.130.162


kubectl apply -f config.yaml

# 신규 버전은(1.13 이후) 위와같은 config 생성하면 안됨
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.10.130.161-10.10.130.162


apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name:network-l2-lb-01
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool

kubectl apply -f network-l2-lb-01.yaml
```

### 2. nginx-ingress 설치 및 구성

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/baremetal/deploy.yaml
```

- 설정 변경(LoadBalancer타입, IP발급)
  k edit -n ingress-nginx svc/ingress-nginx-controller

```
kubectl -n ingress-nginx edit service/ingress-nginx-controller
  type: LoadBalancer
status:
  loadBalancer:
    ingress:
    - ip: 10.10.130.170

```

- pending 상태로 오래있을경우 로그확인

```
kubectl logs `kubectl get po -n kube-system | grep metallb-controller | cut -d' ' -f 1` -n kube-system
```

## 1. Downlad Chart

```
helm repo add harbor https://helm.goharbor.io
helm fetch harbor/harbor --untar

# namespace 생성
kubectl create ns harbor
```

## 2. values.yaml 설정

- expose.tls.enable: true
- expose.tls.secret.secretName: harbor-tls
- caSecretName: harbor-tls
- centSource: secret
- ingress.hosts.core: url 변경 harbor.localhost.com
- ingress.hosts.className: 변경 "nginx"
- externalURL: https://harbor.localhost.com
- persistence 설정: registry, jobservice, database, redis, trivy
  - storageClass 설정: "nfs-client"
- harborAdminPassword: 어드민 계정 비밀번호

## 3. tls를 위한 secret 생성

```
--- root 용 ----
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=KO/ST=Han/OU=Personal/CN=harbor.steco.com" \
 -key ca.key \
 -out harbor.steco.ca.crt
--- domain용 ---
openssl genrsa -out harbor.steco.com.key 4096
# csr 생성
openssl req -sha512 -new \
 -subj "/C=KO/ST=Uk/L=Cheonan/O=Steco/OU=Personal/CN=harbor.steco.com" \
    -key harbor.steco.com.key \
    -out harbor.steco.com.csr
--- x509 v3 extension 파일생성
cat > v3.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=harbor.steco.com
DNS.2=harbor.steco
DNS.3=vminstance's host
EOF
--- v3.ext 파일로 certificate를 생성
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA harbor.steco.ca.crt -CAkey ca.key -CAcreateserial \
    -in harbor.steco.com.csr \
    -out harbor.steco.com.crt
--- # 도커가 쓸 수 있도록 cert로 변환
openssl x509 -inform PEM -in harbor.steco.com.crt -out harbor.steco.com.cert
```

- secret을 통한 tls 설정

```
kubectl create secret tls harbor-tls -n harbor \
--cert=harbor.steco.com.crt \
--key=harbor.steco.com.key
```

## 4. harbor 설치 및 확인

```
helm install harbor -f values.yaml . -n harbor
kubectl get ingress -n harbor #ingress확인
kubectl get pods -n harbor #pod확인
```

## 4. host파일 변경 및 초기 비밀번호로 접속

```
vi /etc/hosts

# 해당 IP는 ingress-controller IP
10.10.130.170 harbor.localhost.com
```

- https://harbor.localhost.com에 접속하여 admin/harborAdminPassword로 접속

## 5. Docker 로그인

```
docker login https://harbor.steco.com
# 계정 이름 및 패스워드 입력
```

![Alt text](./image/harbor_login.png)

## 6. 외부인터넷 되는 서버에서 이미지 가져와서 업로드 방법

- docker image 원격 이동(외부인터넷 단절서버)

```
docker save 이미지명 > 파일명.tar
scp test.tar root@10.10.130.160:/images/test.tar
sudo docker load < test.tar
docker tag jenkins/jenkins:latest harbor.steco.com/infra/jenkins:latest
docker push harbor.steco.com/infra/jenkins:latest
```

![Alt text](./image/harbor_jenkins.png)

## 7. containerd 설정을 통한 docker 미러링

- vi /etc/containerd/config.toml

```
[plugins.cri.registry]
    [plugins.cri.registry.mirrors]
        [plugins.cri.registry.mirrors."docker.io"]
            endpoint = ["http://myharbor.io"]
[plugins.cri.registry.configs."myharbor.io".tls]
    insecure_skip_verify = true
```

## 8. Private Registry에서 image받아오기

- harbor에 접근하기 위한 씨크릿 등록
  https://kubernetes.io/ko/docs/tasks/configure-pod-container/pull-image-private-registry/

```
kubectl create secret docker-registry secret-admin-harbor \
  --docker-username=admin \
  --docker-password=adm01sys! \
  --docker-email=jaeuk730.han@steco.co.kr \
  --docker-server=https://harbor.steco.com/ \
  -n gitlab
```

## 9. containerd - insecure registry 옵션

- /etc/hosts 등록

```
12.xxx.xxx.xxx harbor.steco.com
```

- /etc/containerd/config.toml

```
[plugins.cri.registry]
[plugins.cri.registry.configs."harbor.steco.com".tls]
  insecure_skip_verify = true
```
