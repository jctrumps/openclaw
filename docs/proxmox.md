# Proxmox prerequisites and API permissions

## 1. Select the right environment

Choose your Proxmox node, VMID, datastore, bridge and guest IPv4 address. This deployment does not add a network bridge or NAT. If using a private NAT network, ensure the VM can reach the internet for Docker images, apt and OpenAI OAuth. The controller must reach Proxmox API port 8006 and guest SSH port 22 (directly or via an explicitly configured access path).

The example VMID `2100` is illustrative: confirm it is unused before running apply. Default image is **Ubuntu 24.04**. Your own cloud-init template (placeholder VMID `9000`) needs `cloud-init`, `qemu-guest-agent`, networking, a usable virtual disk, and a valid Ubuntu cloud image. Do not convert an actively running VM to a template.

## 2. VM resources

Suggested start: 4 cores, 8 GiB RAM, 64 GiB disk. Increase resources if OpenClaw agents run multiple coding/build tools, browsers or local models. A remote ChatGPT-hosted model does not require a local GPU. Treat guest disk, VM backups and the host's backup targets as sensitive because OAuth credentials persist there.

## 3. Proxmox API token

Recommended: create a dedicated Proxmox user, a narrowly scoped role and token in the Proxmox UI. Assign only privileges needed to clone the template, allocate the VM/disks, modify VM configuration and power it on. Common requirements include `VM.Allocate`, `VM.Clone`, `VM.Config.*`, `VM.PowerMgmt`, `Datastore.AllocateSpace` and datastore audit rights. Exact requirements depend on your storage and Proxmox/provider versions. If you see `403 Datastore.AllocateSpace`, fix the token *permissions on the destination datastore*; do not place a root token in Git.

Use API token format:

```text
user@pve!token_name=SECRET_VALUE
```

On the **controller** only:

```bash
read -r -s -p 'Proxmox API token: ' PROXMOX_VE_API_TOKEN; echo
export PROXMOX_VE_API_TOKEN
```

Paste token only into the hidden prompt. The provider reads the `PROXMOX_VE_API_TOKEN` environment variable. To remove from current shell after provisioning: `unset PROXMOX_VE_API_TOKEN`. Never commit it or put it into `terraform.tfvars`.

## 4. Template + clone expectations

OpenTofu uses `proxmox_virtual_environment_vm` with `clone { vm_id = 9000; full = true }` and a separate `scsi0` disk definition. Depending on the original template disk layout and datastore, you may need to adjust the disk block (for example, if your template uses a different interface) before applying. Run `tofu plan` and inspect for unexpected disk changes. Version of `bpg/proxmox` is limited by `versions.tf`; review release notes when upgrading.

## 5. Addressing

**Static mode:** `ipv4_address = "192.0.2.55/24"`, `ipv4_gateway = "192.0.2.1"`. The generated Ansible inventory uses the address without CIDR.

**DHCP mode:** set both fields `null`; the generated inventory uses the VM name and requires working name resolution (`getent hosts openclaw-01`) on the controller. If name resolution fails, edit the **ignored generated inventory** after apply to use the DHCP-assigned address.

## 6. No router forwarding required

Cloudflare Tunnel initiates outbound connections from the guest. Do not port forward TCP/18789 or expose it on a Proxmox public bridge. When installing cloudflared manually on the **same guest**, its upstream origin is local `http://127.0.0.1:18789`.
