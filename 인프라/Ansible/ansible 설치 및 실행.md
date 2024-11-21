# 1. ANSIBLE 설치

## 1. ANSIBLE installation

- https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-fedora-linux

1. OS에 따른 설치 명령이 다름(Fedora Linux 기준으로 설치 진행함)

- 기본적으로 windwos에는 설치 불가

```
 dnf install epel-release
 dnf install ansible
```

2. 설치 버전 확인

```
ansible --version
```

# 2. ansible 실행 및 테스트

## 1. ssh key 생성 및 원격서버 키 삽입

1. ssh key 생성

```
ssh-keygen

# 저장 위치 /root/.ssh/id_rsa
```

2. key원격 서버 복사

```
ssh-copy-id [원격서버계정ID]@[원격서버IP]
ssh-copy-id root@10.100.100.201
```

3. 접속 확인

```
ssh root@10.100.100.201
```

## 2. ansible test

1. 인벤토리 작성

```
vi /etc/ansible/hosts

[git]
10.100.100.100
10.100.100.101
```

2. ansible을 통한 정상 접속 테스트 확인

```
ansible all -m ping
```

```
10.100.100.101 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
10.100.100.100 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
```

# 3. ansible playbook

# 4. 구성파일 및 주요 명령어

1. 구성파일

- /etc/ansible/ansible.cfg: ansible 환경 설정 파일
- /etc/ansible/hosts: ansible이 접속하는 호스트 서버 파일(그룹지정 가능)

2. 명령어

- Ansible imperative command 명령어 정보
  -i (--inventory-file) : 적용될 호스트들에 대한 파일
  -m ( --module-name ) : 모듈을 선택할 수 있도록
  -k (--ask-pass) 패스워드 물어보도록 설정
  -K (--ask-become-pass) root로 권한 상승
  --list-hosts: 적용되는 호스트들을 확인
- ansible all -m shell -a "swapoff -a" -K
