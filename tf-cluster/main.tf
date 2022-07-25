terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.10"
    }
  }
}

provider "proxmox" {
  pm_api_url  = var.proxmox_api_url
  pm_user     = var.proxmox_api_username
  pm_password = var.proxmox_api_password
  # pm_tls_insecure     = true

  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_debug      = true

  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}

# resource is formatted to be "[type]" "[entity_name]" so in this case
# we are looking to create a proxmox_vm_qemu entity named test_server
resource "proxmox_vm_qemu" "kube_control_plane" {
  count = 1
  vmid  = 1000 + 10 + count.index
  name  = format("kube-control-plane-%02s", count.index + 1)

  target_node = var.proxmox_host
  clone       = var.template_name

  agent    = 1
  os_type  = "cloud-init"
  cores    = 8
  sockets  = 1
  cpu      = "host"
  memory   = 2048
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot     = 0
    size     = "10G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=192.168.104.${count.index + 10}/24,gw=192.168.104.1"
  ipconfig1 = "ip=10.0.0.${count.index + 10}/24"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}

# resource is formatted to be "[type]" "[entity_name]" so in this case
# we are looking to create a proxmox_vm_qemu entity named test_server
resource "proxmox_vm_qemu" "kube_worker" {
  count = 2
  name  = format("kube-worker-%02s", count.index + 1)
  vmid  = 1000 + 20 + count.index

  # this now reaches out to the vars file.
  # I could've also used this var above in the pm_api_url setting but wanted to spell it out up there.
  # target_node is different than api_url.
  # target_node is which node hosts the template and thus also which node will host the new VM.
  # it can be different than the host you use to communicate with the API.
  target_node = var.proxmox_host

  clone = var.template_name

  agent    = 1
  os_type  = "cloud-init"
  cores    = 8
  sockets  = 1
  cpu      = "host"
  memory   = 2048
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"

  disk {
    slot     = 0
    size     = "10G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=192.168.104.${count.index + 20}/24,gw=192.168.104.1"
  ipconfig1 = "ip=10.0.0.${count.index + 20}/24"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}
