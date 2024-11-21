# 1. Kube Dashboard 구성

## 1. metirc server 설치

- https://github.com/kubernetes-sigs/metrics-server/releases

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.0/components.yaml

#metric server 확인
kubectl get pod -n kube-system
```

- mertric server 수정(deployment)

```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=10250
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls # 변경되면서 업데이트 진행됨
        image: registry.k8s.io/metrics-server/metrics-server:v0.7.0
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /livez
            port: https
            scheme: HTTPS
          periodSeconds: 10
        name: metrics-server
        ports:
        - containerPort: 10250
          name: https
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /readyz
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          seccompProfile:
            type: RuntimeDefault
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      serviceAccountName: metrics-server
      volumes:
      - emptyDir: {}
        name: tmp-dir
EOF
```

## 2. Kube dashboard 구성

- 참조 사이트 : https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
- 배포

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

- 접근할 계정 생성 및 권한 부여

```
cat <<EOF | kubectl apply -f -
# 계정 생성
apiVersion: v1
kind: ServiceAccount #pod가 사용하는 계정
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
# 권한 부여 (view, edit, admin 등등 존재)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding #클러스터의 역할을 binding
metadata:
  name: admin-user
roleRef: #어떤 권한을
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin # 클러스터 관리자 권한
subjects: #누구에게?
- kind: ServiceAccount
  name: admin-user # 계정 정보
  namespace: kubernetes-dashboard
EOF

# 앞서 생성한 계정으로 토큰을 발급한다.
kubectl -n kubernetes-dashboard create token admin-user
# 등록한 계정 토큰 확인
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
```

- NodePort 서비스로 변경

```
kubectl edit svc kubernetes-dashboard -n kubernetes-dashboard
#변경 내용
# nodePort: 30443  type: NodePort
```

- docker image 원격 이동(외부인터넷 단절서버)

```
docker save 이미지명 > 파일명.tar
scp test.tar root@10.10.130.160:/images/test.tar
sudo docker load < test.tar
docker push harbor.steco.com/<project_name>/<image_name>:<TAG>
```
