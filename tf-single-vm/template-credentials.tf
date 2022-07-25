variable "proxmox_api_url" {
  type    = string
  default = "https://proxmox.tebeclone.com/api2/json"
}

variable "proxmox_api_username" {
  type    = string
  default = "terraform@pve"
}

variable "proxmox_api_password" {
  type    = string
  default = "CHANGE_ME"
}
