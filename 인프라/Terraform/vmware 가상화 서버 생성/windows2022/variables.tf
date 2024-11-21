variable "vsphere_server" {
  description = "vSphere server"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "datacenter" {
  description = "vSphere data center"
  type        = string
}

variable "cluster" {
  description = "vSphere cluster"
  type        = string
}

variable "datastore" {
  description = "vSphere datastore"
  type        = string
}

variable "network_name" {
  description = "vSphere network name"
  type        = string
}

variable "windows_name" {
  description = "Ubuntu name (ie: image_path)"
  type        = string
}

variable "virtual_system_name" {
  description = "virtual_system_name"
  type        = string
}

variable "vm_num_cpus" {
  description = "Number of CPUs for the virtual machine"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory (in MB) for the virtual machine"
  type        = number
  default     = 4096
}

variable "vm_disk_size" {
  description = "Disk size (in GB) for the virtual machine"
  type        = number
  default     = 90
}