output "vm_name" { value = proxmox_virtual_environment_vm.openclaw.name }
output "vm_id" { value = proxmox_virtual_environment_vm.openclaw.vm_id }
output "ssh_hint" { value = "ssh -i ${var.ssh_private_key_file} ${var.ssh_username}@${local.ansible_host}" }
output "inventory_path" { value = local_sensitive_file.inventory.filename }
