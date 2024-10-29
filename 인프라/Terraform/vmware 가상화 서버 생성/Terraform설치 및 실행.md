# 1. Terraform 설치

## 1. Terraform installation

- https://developer.hashicorp.com/terraform/install

1. OS와 hw architecture에 따라 선택

```
- 폐쇄망 O: OS와 architecture 맞는 파일download
- 폐쇄망 X: install 명령어 실행
```

2. 환경 변수 설정

```
검색: 시스템 환경변구 편집 -> 환경변수 -> 시스템 변수: PATH -> Download한 파일 경로 설정
ex) C:\Program Files\terraform_1.8.5_windows_amd64
```

3. terraform 작동 확인

- powershell 실행 후 아래 명령어 입력

```
terraform version

Terraform v1.8.5
on windows_amd64
```

## 2. Terraform Provider for VMware vSphere install

- 공식 문서: https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs
- terraform-provider-vsphere download: https://github.com/hashicorp/terraform-provider-vsphere/blob/main/docs/INSTALL.md

### - Windows installlation( 2.7.0 version 으로 진행 )

1. 인터넷이 되는 환경에서 powershell 명령어를 입력해서 zip파일 다운로드

```
$RELEASE="2.7.0"
Invoke-WebRequest https://releases.hashicorp.com/terraform-provider-vsphere/${RELEASE}/terraform-provider-vsphere_${RELEASE}_windows_amd64.zip -outfile terraform-provider-vsphere_${RELEASE}_windows_amd64.zip
```

2. 플러그인 추출(압축해제)

```
Expand-Archive terraform-provider-vsphere_${RELEASE}_windows_amd64.zip

cd terraform-provider-vsphere_${RELEASE}_windows_amd64
```

3. 추출한 플러그인 terraform 플러그인 디렉터리로 복사

```
New-Item $ENV:APPDATA\terraform.d\plugins\local\hashicorp\vsphere\${RELEASE}\ -Name "windows_amd64" -ItemType "directory"

Move-Item terraform-provider-vsphere_v${RELEASE}_x5.exe $ENV:APPDATA\terraform.d\plugins\local\hashicorp\vsphere\${RELEASE}\windows_amd64\terraform-provider-vsphere_v${RELEASE}.exe
```

4. 플러그인 디렉터리 확인

```
cd $ENV:APPDATA\terraform.d\plugins\local\hashicorp\vsphere\${RELEASE}\windows_amd64
dir
```

# 2. Terraform 실행

## 1. 폐쇄망 환경에서 Terraform 실행

- main.tf를 토대로 설명(참조 바람)

1. 폐쇄망인 경우 local/hashicorp/vsphere 부분이 필요(플러그인 2번을 참조해서 다운로드 )

```
terraform {
  required_providers {
    vsphere = {
      source = "local/hashicorp/vsphere"
      version = "2.7.0"
    }
  }
  required_version = ">= 0.13"
}
```

2. Provider, data, resource 영역으로 구분

```
1. Provider(vsphere에 접근하기 위한 설정 옵션) :user, password, server_url or ip 필요
2. data(vsphere에 적혀있는 값들을 넣어줘야함): datacenter, cluster, datastore, network, template 필요(미리 생성된 template)
3. resource(생성할 vm 리소스를 적어줄 곳): 가상화 이름, cpu, memory,disk 등 필요
```

3. main.tf 파일 완성 후 명령어 실행 현황

```
# terraform 초기화: plugin module 버전확인 및 초기화 .terraform 폴더와.terraform.lock.hcl파일 생성
terraform init

# 배포할 resource 확인 및 추가할 resource는 +로 표기 됨
terraform plan

# resource를 배포하여 vsphere를 vmware 생성, action 수행하기 위해 Enter a yes
terraform apply
```

- Terraform을 통한 vmware 생성 화면
  ![Alt text](terraform_windows.PNG)

## 2. 폐쇄망이 아닌경우

- 자동적으로 플러그인이 다운로드 되며 설정값만 잘 설정
- docs 참조: https://registry.terraform.io/providers/hashicorp/vsphere/latest/docs
