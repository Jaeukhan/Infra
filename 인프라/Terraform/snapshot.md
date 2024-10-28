```
# terraform vsphere snapshot
resource "vsphere_virtual_machine_snapshot" "win2022_snapshot" {
virtual_machine_uuid = "e33d9f65-7ee0-eb94-7d97-6cfe5472b4b8"
snapshot_name = "windows_240624"
description = "Regular Q2 backup"
memory = "true"
quiesce = "true"
remove_children = "false"
consolidate = "true"
}

```