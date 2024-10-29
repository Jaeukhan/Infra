terraform {
  # local vsphere version 확인
  required_providers {
    vsphere = {
      source = "local/hashicorp/vsphere"
      version = "2.7.0"
    }
  }
  required_version = ">= 0.13"
}

provider "vsphere" {
  # Configuration options
  user                 = "administrator_vsphere"
  password             = "password"
  vsphere_server       = "10.100.100.98"
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = "VxRail-Datacenter"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "VxRail-Virtual-SAN-Cluster"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


data "vsphere_datastore" "datastore" {
  name          = "VxRail-Virtual-SAN-Datastore"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


data "vsphere_network" "network" {
  # DMZ 존 NETWORK 변경 시 NAME 변경
  name          = "Internal VM Network"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  # 기존에 생성한 vmware template 이름 참조
  name          = "Win2022-64"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}     

resource "vsphere_virtual_machine" "vm" {
  # 생성할 vmware 이름: name,  cpus: cpu 수, memory: 메모리 값, disk : 디스크 크기(기존 디스크 크기 90GB이라서 90이상 값 설정)
  name             = "windows-vsphere-test"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 2
  memory           = 4096
  guest_id         = "windows2019srvNext_64Guest"
  firmware = "efi"
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label = "disk0"
    size  = 90
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}