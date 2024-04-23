# 1. Argo CD 구성

## 1. Argo CD 설치

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd

#helm chart를 이용하여 설치
helm repo add argo-cd https://argoproj.github.io/argo-helm
```

## 2. Argo CD ingress설정

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argo-ingress
  namespace:argocd
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    kubernetes.io/ingress.class: "nginx"
  labels:
    app: argos
spec:
  rules:
  - host: "argo.company.com"
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name:  argocd-server
            port:
              number: 80
status:
  loadBalancer:
    ingress:
    - ip: 12.xxx.xxx.162
```

```
vim /etc/hosts
#추가
12.xxx.xxx.170 argo.company.com
```

## 3. Argo cd 초기비밀번호

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### 4. 사용방법

Applications -> New App -> Application Repository 및 설정
