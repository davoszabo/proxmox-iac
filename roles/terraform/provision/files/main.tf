resource "proxmox_virtual_environment_vm" "node" {
  for_each        = local.vms

  vm_id           = each.value.id
  name            = each.value.name
  tags            = try(each.value.config.tags, null)
  node_name       = each.value.config.target_node
  keyboard_layout = try(each.value.config.keyboard_layout, "hu")

  clone {
    vm_id         = each.value.config.template_id
    full          = true
  }

  agent {
    enabled = each.value.config.agent
  }

  cpu {
    cores         = each.value.config.cores
    type          = each.value.config.cpu_type
  }

  memory {
    dedicated     = each.value.config.memory
  }

  network_device {
    bridge        = try(each.value.config.network_bridge, "vmbr0")
    model         = try(each.value.config.network_model, "virtio")
  }

  serial_device {
    device        = try(each.value.config.serial_device, "socket")
  }
  vga {
    type          = try(each.value.config.vga_type, "serial0")
  }

  disk {
    interface     = "scsi0"
    datastore_id  = each.value.config.storage_pool
    size          = each.value.config.storage_size_gb
    ssd           = each.value.config.storage_ssd
  }
  boot_order      = try(each.value.config.boot_order, ["scsi0"])
  scsi_hardware   = try(each.value.config.scsi_hardware, "virtio-scsi-pci")

  initialization {
    # uncomment and specify the datastore for cloud-init disk if default `local-lvm` is not available
    datastore_id        = each.value.config.storage_pool

    ip_config {
      ipv4 {
        address         = "${each.value.ip}/24"
        gateway         = each.value.config.gateway
      }
    }

    user_account {
      username = each.value.config.user
      password = try(each.value.config.password, null)
      keys     = length(trimspace(try(each.value.config.ssh_pubkey, ""))) > 0 ? [each.value.config.ssh_pubkey] : []
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
