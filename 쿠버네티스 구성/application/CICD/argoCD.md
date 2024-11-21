# 1. Argo CD 구성

## 1. Argo CD 설치

```
kubectl create namespace cicd
kubectl apply -n cicd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n cicd

#helm chart를 이용하여 설치
helm repo add argo-cd https://argoproj.github.io/argo-helm
```

## 2. Argo CD ingress설정

- https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#kubernetesingress-nginx

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: cicd
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
	nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.steco.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              name: https
  tls:
  - hosts:
    - argocd.steco.com
    secretName: argocd-secret # do not change, this is provided by Argo CD
```

```
vim /etc/hosts
#추가
10.10.130.170 argo.steco.com
```

## 3. Argo cd 초기비밀번호

```
kubectl -n cicd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### 4. 사용방법

Applications -> New App -> Application Repository 및 설정
