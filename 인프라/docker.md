# [1] 가상화 개념과 Container 그리고 Docker

## 1] 가상화
- 물리 하드웨어에 종속된 리소스를 사용해 시뮬레이션 환경이나 전용 리소스를 생성하는 기술
- 서버를 파티셔닝 및 효율적인 사용을 위해 사용
## 2] 하이퍼바이저
- 소프트웨어가 물리 리소스를 필요로하는 가상환경으로부터 물리 리소스를 분리
- type1) 하드웨어 위에 hypervisor(kvm, qemu...)  type2)하드웨어 - os - hypervisor(개인이 공부할 때 사용)

## 3] Container
- Linux에 namespace를 사용하여 서비스를 격리하는 기술(외부로 쉽게 나갈 수 없게 격리해둔 것)
- 하드웨어를 구현하지 않기 때문에 빠르게 생성가능.
- Union Mount File System 사용(중복 최대한 제거): 동일한 디렉터리에 여러개의 파일시스템을 마운트하는 기술
	- Lower layer(base image layer)와 Upperlayer(Container layer)가 존재

## 4] Docker
- 컨테이너 기술을 잘 사용할 수 있게 도와주는 도구. 어플리케이션 뿐만아니라 파일시스템, 의존성을 패키징 함.
1. Docker CLI - client로 Docker daemon에 명령을 전달
2. Docker Daemon - 컨테이너 실행, 관리의 작업
3. Containerd - 핵심 컨테이너 런타임(쿠버네티스에서도 이용)
4. 런타임(runc) - 저수준 컨테이너 런타임
- 컨테이너: 이미지를 격리하여 독립된 공간에서 실행한 가상환경
- 이미지: 의존성, app, 파일시스템 패키징한 파일시스템
- 레지스트리: 이미지를 저장하는 저장소(Docker hub, Harbor ... )
- 명령어
```
	docker pull image_name:tags
	docker ps -a
	docker run -d -p 포트(호스트:컨테이너) --naame name image_name:tags
	docker inspect 이미지_or_컨테이너  #포트 및 layer확인 가능
	docker logs container_name
	docker exec -it(input tty) container_name bash
	docker rm cname (+ docker rm $(docker ps -a -q) )
	docker images
	docker rmi img (+ docker rm $(docker images -q) )
	docker create -p 포트(호스트:컨테이너) --naame name image_name:tags
	docker start cname
	docker cp 호스트 컨테이너:패스( docker cp 컨테이너:패스 호스트)
```
