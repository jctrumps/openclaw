variable "proxmox_endpoint" {
  description = "Proxmox VE API URL, e.g. https://192.0.2.10:8006/"
  type        = string
}
variable "proxmox_insecure" {
  description = "Allow self-signed Proxmox API certificate; use false with trusted certificates."
  type        = bool
  default     = false
}
variable "node_name" {
  description = "Target Proxmox node name (not its DNS name)."
  type        = string
}
variable "template_vm_id" {
  description = "Existing Ubuntu 24.04 cloud-init template VMID; replace sample with your own."
  type        = number
  default     = 9000
}
variable "vm_id" {
  description = "Unused VMID for OpenClaw."
  type        = number
  default     = 2100
}
variable "vm_name" {
  description = "Guest VM name."
  type        = string
  default     = "openclaw-01"
}
variable "cpu_cores" {
  type    = number
  default = 4
}
variable "memory_mb" {
  type    = number
  default = 8192
}
variable "disk_size_gb" {
  type    = number
  default = 64
}
variable "datastore_id" {
  type    = string
  default = "local-lvm"
}
variable "bridge" {
  type    = string
  default = "vmbr0"
}
variable "cpu_type" {
  type    = string
  default = "host"
}
variable "ipv4_address" {
  description = "IPv4 CIDR e.g. 192.0.2.55/24. Use null for DHCP plus working DNS."
  type        = string
  default     = null
}
variable "ipv4_gateway" {
  description = "Gateway for static IP; null with DHCP."
  type        = string
  default     = null
}
variable "ssh_username" {
  type    = string
  default = "ubuntu"
}
variable "ssh_public_key" {
  description = "Entire authorized SSH public key text, from cat ~/.ssh/openclaw_01_ed25519.pub."
  type        = string
}
variable "ssh_private_key_file" {
  description = "Absolute Linux/WSL path to matching private key, used ONLY in generated local Ansible inventory."
  type        = string
}
