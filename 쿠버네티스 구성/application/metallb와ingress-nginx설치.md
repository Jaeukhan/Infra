# 1. metalLB 설치 및 구성

## 1. bitnami repo추가와 metallb 설치

```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm search repo bitnami
helm show values elastic/elasticsearch > elasticsearch-value.yaml
```

- config map 미설정 되어있을 시

```
kubectl get cm/metallb-config -n kube-system -o jsonpath='{.data.config}'
# 값이 null로 뜬다면

k edit cm/metallb-config -n kube-system
#추가
address-pools:
- name: default
  protocol: layer2
  addresses:
  - 192.168.1.240-192.168.1.250
```

## 2. ingress-nginx 설치

```
helm install nginx bitnami/nginx-ingress-controller -n kube-system
kubectl get svc -n kube-system
```
