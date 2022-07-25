variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_username" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_password" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

source "proxmox" "ubuntu-server-jammy" {
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_username
  password                 = var.proxmox_api_password
  // username                 = var.proxmox_api_token_id
  // token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  node                = "proxmox"
  vm_id               = 400
  vm_name             = "ubuntu-server-jammy"
  template_description = "whatever"

  iso_file         = "local:iso/ubuntu-22.04-live-server-amd64.iso"
  iso_storage_pool = "local"
  unmount_iso      = true

  qemu_agent = true

  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size         = "10G"
    format            = "raw"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm"
    type              = "virtio"
  }

  cores  = 4
  memory = "2048"

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot      = "c"
  boot_wait = "5s"

  http_directory = "http"
  # (Optional) Bind IP Address and Port
  // http_bind_address = "172.18.4.70"
  // http_port_min = 4000
  // http_port_max = 4000

  ssh_username         = "tebeco"
  ssh_private_key_file = "~/.ssh/kube-key-ecdsa"
  ssh_timeout          = "20m"
}

# Build Definition to create the VM Template
build {

  name    = "ubuntu-server-jammy"
  sources = ["source.proxmox.ubuntu-server-jammy"]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }
}
