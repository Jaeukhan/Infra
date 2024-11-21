# 엘라스틱스택 구성(ELK)

## 1. 엘라스틱 레포 추가 및 업데이트

```
  helm repo add elastic https://helm.elastic.co
  helm repo update

  mkdir elastic
  cd elastic
```

- repo 내용확인

```
 helm search repo elastic
```

## 2. elastic yaml file 다운로드 및 옵션 수정

```
  helm show values elastic/elasticsearch > elasticsearch-values.yaml\
  helm show values elastic/kibana > kibana-values.yaml
```

- 옵션 수정

```
  vim elasticsearch-value.yaml
  # replicas 수, secret: password 설정
  # cpu:500, moemory:1Gi, persistence, volume, ingress
  vim kibana-values.yaml
  # resources: cpu:400, memory: 400Mi
```

## 3. Volume 생성

```
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: standard
  name: elasticsearch-master
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 500Gi
  nfs:
    path: /data/elastic
    server: 10.10.123.16
  persistentVolumeReclaimPolicy: Retain
  #storageClassName: nfs-standard
  volumeMode: Filesystem
```

## 4. elastic 배포

```
kubectl create ns logging
helm install elasticsearch elastic/elasticsearch -n logging -f elasticsearch-values.yaml
# helm install elasticsearch -n logging oci://harbor.steco.com/helm/elasticsearch --ca-file harbor.steco.com.crt
helm install kibana elastic/kibana -n logging -f kibana-values.yaml
```

```
# 재설정 시 pv 강제 삭제
kubectl patch pv elasticsearch-master -p '{"metadata": {"finalizers": null}}'
kubectl delete pv elasticsearch-master --grace-period=0 --force

# elasticsearch upgrade
helm upgrade elasticsearch elastic/elasticsearch -n logging -f elasticsearch-values.yaml
```

- kibana의 문제 있을경우

```
# 자동 배포된 자원 삭제하기
cd ~/elastic
kubectl delete role --all -n logging
kubectl delete rolebinding --all -n logging
kubectl delete sa --all -n logging
kubectl delete configmaps --all -n logging
kubectl delete jobs --all -n logging
kubectl delete secret sh.helm.release.v1.kibana.v1 -n logging
kubectl delete secret kibana-kibana-es-token -n logging
kubectl delete deployment --all -n logging

helm uninstall kibana -n logging
helm install kibana elastic/kibana -n logging -f kibana-values.yaml
# helm upgrade kibana elastic/kibana -n logging -f kibana-values.yaml
```

- kibana svc Nodeport변경

```
kubectl expose deployment kibana-kibana --type=NodePort  --name=kibana-svc -n logging
```

- logstash 설치

  - logstash yaml 파일 다운

  ```
  helm show values elastic/logstash > logstash-values.yaml

  #수정
  persistence : enabled: true
  http.host: 0.0.0.0
  ```

- logstash pv volume

```
cat << EOF > pv-logstash.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: standard
  name: logstash
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 1Gi
  nfs:
    path: /data/logstash
    server: 10.10.123.16
  persistentVolumeReclaimPolicy: Retain
  #storageClassName: nfs-standard
  volumeMode: Filesystem
EOF
kubectl apply -f pv-logstash.yaml
```

- configMap 생성(logstash.conf를 위한)

```
cat << EOF > logstash-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: logging
  name: logstash-configmap
  labels:
    task: logging
    k8s-app: logstash
data:
  logstash.yml: |
    http.host: "127.0.0.0"
    path.config: /usr/share/logstash/pipeline
  logstash.conf:
    input
    {
      tcp
      {
        port => 5000
      }
    }
    filter
    {
      json
      {
        source => "message"
        remove_field => ["@version","beat","count","fields","input_type","offset","source","host","tags","port","message"]
      }
    }
    output
    {
      elasticsearch
      {
        hosts => ["elasticsearch:9200"]
        manage_template => false
        index => "my_index"
        document_type => "doc"
      }
    }
EOF
kubectl apply -f logstash-configmap.yaml -n logging
```

- logstash 설치 및 설정변경

```
helm install logstash elastic/logstash -n logging -f logstash-values.yaml
# helm upgrade logstash elastic/logstash  -n logging -f logstash-values.yaml
```

- 기본 비밀번호 찾기

```
echo $(kubectl get secret -n logging elasticsearch-master-credentials -o jsonpath='{.data.password}') | base64 -d
```

- pvc 강제삭제
  kubectl patch pv logstash -p '{"metadata":{"finalizers":null}}'
