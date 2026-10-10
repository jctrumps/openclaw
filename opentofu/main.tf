resource "proxmox_virtual_environment_vm" "openclaw" {
  name        = var.vm_name
  description = "OpenClaw Docker gateway; provisioned by OpenTofu and managed by Ansible"
  node_name   = var.node_name
  vm_id       = var.vm_id
  tags        = ["openclaw", "opentofu", "ansible"]

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_mb
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size_gb
  }

  initialization {
    user_account {
      username = var.ssh_username
      keys     = [trimspace(var.ssh_public_key)]
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address == null ? "dhcp" : var.ipv4_address
        gateway = var.ipv4_address == null ? null : var.ipv4_gateway
      }
    }
  }

  started = true
}

locals {
  ansible_host = var.ipv4_address == null ? var.vm_name : split("/", var.ipv4_address)[0]
}

resource "local_sensitive_file" "inventory" {
  filename        = "${path.module}/../ansible/inventory/hosts.ini"
  file_permission = "0600"
  content         = <<-EOT
    [openclaw]
    ${var.vm_name} ansible_host=${local.ansible_host} ansible_user=${var.ssh_username} ansible_python_interpreter=/usr/bin/python3 ansible_ssh_private_key_file=${var.ssh_private_key_file} ansible_ssh_common_args='-o IdentitiesOnly=yes'
    EOT
}
