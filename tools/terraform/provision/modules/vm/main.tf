resource "proxmox_virtual_environment_vm" "node" {
  vm_id     = var.vm_id
  name      = var.name
  tags      = try(var.config.tags, null)
  node_name = var.config.target_node
  # A changed VM_target_node migrates the VM instead of destroy/re-create (blocked by prevent_destroy).
  # After a manual migration in Proxmox, update VM_target_node, or the next apply migrates it back.
  migrate         = true
  keyboard_layout = try(var.config.keyboard_layout, "hu")

  clone {
    vm_id = var.config.template_id
    # Node holding the template, if it differs from target_node. On non-shared storage the provider
    # clones there and then migrates the clone to target_node (needs VM.Migrate on the token).
    node_name = try(var.config.template_node, null)
    full      = true
  }

  agent {
    enabled = var.config.agent
  }

  cpu {
    cores = var.config.cores
    type  = var.config.cpu_type
  }

  # Proxmox semantics: `memory` (dedicated) is the maximum, `balloon` (floating) the guaranteed minimum.
  # Inventory: VM_memory is the guaranteed amount; VM_memory_balloon_max, if set, enables ballooning up
  # to that size. Unset keeps floating = 0 (no balloon device), the provider default.
  memory {
    dedicated = try(var.config.memory_balloon_max, var.config.memory)
    floating  = can(var.config.memory_balloon_max) ? var.config.memory : 0
  }

  network_device {
    bridge = try(var.config.network_bridge, "vmbr0")
    model  = try(var.config.network_model, "virtio")
  }

  serial_device {
    device = try(var.config.serial_device, "socket")
  }
  vga {
    type = try(var.config.vga_type, "serial0")
  }

  disk {
    interface    = "scsi0"
    datastore_id = var.config.storage_pool
    size         = var.config.storage_size_gb
    ssd          = var.config.storage_ssd
    # Pass guest TRIM through so thin storage (ZFS, LVM-thin) reclaims freed blocks.
    discard = try(var.config.storage_discard, "on")
  }
  boot_order    = try(var.config.boot_order, ["scsi0"])
  scsi_hardware = try(var.config.scsi_hardware, "virtio-scsi-pci")

  initialization {
    # uncomment and specify the datastore for cloud-init disk if default `local-lvm` is not available
    datastore_id = var.config.storage_pool

    ip_config {
      ipv4 {
        address = "${var.ip}/${try(var.config.ip_cidr, 24)}"
        gateway = var.config.gateway
      }
    }

    user_account {
      username = var.config.user
      password = try(var.config.password, null)
      keys     = length(trimspace(try(var.config.ssh_pubkey, ""))) > 0 ? [var.config.ssh_pubkey] : []
    }
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      vm_id,
      name,
      initialization[0].user_account[0].keys,
    ]
  }
}
