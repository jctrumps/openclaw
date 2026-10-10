provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure
  # Read API credentials from PROXMOX_VE_API_TOKEN environment variable.
  # DO NOT put API credentials in tfvars or tracked source.
}
