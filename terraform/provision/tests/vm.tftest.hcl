mock_provider "proxmox" {}

variables {
  proxmox = {
    endpoint     = "https://proxmox.example.com:8006"
    api_token    = "user@pve!token=fake"
    tls_insecure = true
  }
}

run "ip_cidr_defaults_to_24" {
  command = plan

  variables {
    vms = {
      test-vm = {
        name = "test-vm"
        ip   = "10.0.0.5"
        id   = 9000
        config = {
          target_node     = "pve1"
          template_id     = 9001
          agent           = true
          cores           = 2
          cpu_type        = "host"
          memory          = 2048
          storage_pool    = "local-lvm"
          storage_size_gb = 20
          storage_ssd     = true
          gateway         = "10.0.0.1"
          user            = "debian"
        }
      }
    }
  }

  assert {
    condition     = module.vm["test-vm"].vm.initialization[0].ip_config[0].ipv4[0].address == "10.0.0.5/24"
    error_message = "Expected default CIDR of /24 when config.ip_cidr is unset"
  }
}

run "ip_cidr_override" {
  command = plan

  variables {
    vms = {
      test-vm = {
        name = "test-vm"
        ip   = "10.0.0.5"
        id   = 9000
        config = {
          target_node     = "pve1"
          template_id     = 9001
          agent           = true
          cores           = 2
          cpu_type        = "host"
          memory          = 2048
          storage_pool    = "local-lvm"
          storage_size_gb = 20
          storage_ssd     = true
          gateway         = "10.0.0.1"
          user            = "debian"
          ip_cidr         = 26
        }
      }
    }
  }

  assert {
    condition     = module.vm["test-vm"].vm.initialization[0].ip_config[0].ipv4[0].address == "10.0.0.5/26"
    error_message = "Expected config.ip_cidr = 26 to override the default"
  }
}

run "optional_fields_default" {
  command = plan

  variables {
    vms = {
      test-vm = {
        name = "test-vm"
        ip   = "10.0.0.5"
        id   = 9000
        config = {
          target_node     = "pve1"
          template_id     = 9001
          agent           = true
          cores           = 2
          cpu_type        = "host"
          memory          = 2048
          storage_pool    = "local-lvm"
          storage_size_gb = 20
          storage_ssd     = true
          gateway         = "10.0.0.1"
          user            = "debian"
        }
      }
    }
  }

  assert {
    condition     = module.vm["test-vm"].vm.keyboard_layout == "hu"
    error_message = "Expected default keyboard_layout of 'hu'"
  }

  assert {
    condition     = module.vm["test-vm"].vm.tags == null
    error_message = "Expected tags to be null when config.tags is unset"
  }

  assert {
    condition     = module.vm["test-vm"].vm.network_device[0].bridge == "vmbr0"
    error_message = "Expected default network_device.bridge of 'vmbr0'"
  }

  assert {
    condition     = module.vm["test-vm"].vm.network_device[0].model == "virtio"
    error_message = "Expected default network_device.model of 'virtio'"
  }

  assert {
    condition     = module.vm["test-vm"].vm.serial_device[0].device == "socket"
    error_message = "Expected default serial_device of 'socket'"
  }

  assert {
    condition     = module.vm["test-vm"].vm.vga[0].type == "serial0"
    error_message = "Expected default vga.type of 'serial0'"
  }

  assert {
    condition     = tolist(module.vm["test-vm"].vm.boot_order) == tolist(["scsi0"])
    error_message = "Expected default boot_order of ['scsi0']"
  }

  assert {
    condition     = module.vm["test-vm"].vm.scsi_hardware == "virtio-scsi-pci"
    error_message = "Expected default scsi_hardware of 'virtio-scsi-pci'"
  }

  assert {
    condition     = module.vm["test-vm"].vm.initialization[0].user_account[0].password == null
    error_message = "Expected password to be null when config.password is unset"
  }

  assert {
    condition     = length(module.vm["test-vm"].vm.initialization[0].user_account[0].keys) == 0
    error_message = "Expected no SSH keys when config.ssh_pubkey is unset"
  }
}

run "optional_fields_override" {
  command = plan

  variables {
    vms = {
      test-vm = {
        name = "test-vm"
        ip   = "10.0.0.5"
        id   = 9000
        config = {
          target_node     = "pve1"
          template_id     = 9001
          agent           = true
          cores           = 2
          cpu_type        = "host"
          memory          = 2048
          storage_pool    = "local-lvm"
          storage_size_gb = 20
          storage_ssd     = true
          gateway         = "10.0.0.1"
          user            = "debian"
          keyboard_layout = "en-us"
          tags            = ["dev", "web"]
          network_bridge  = "vmbr1"
          network_model   = "e1000"
          serial_device   = "/dev/ttyS0"
          vga_type        = "std"
          boot_order      = ["scsi0", "net0"]
          scsi_hardware   = "lsi"
          password        = "s3cret"
          ssh_pubkey      = "ssh-ed25519 AAAATESTKEY"
        }
      }
    }
  }

  assert {
    condition     = module.vm["test-vm"].vm.keyboard_layout == "en-us"
    error_message = "Expected config.keyboard_layout to override the default"
  }

  assert {
    condition     = tolist(module.vm["test-vm"].vm.tags) == tolist(["dev", "web"])
    error_message = "Expected config.tags to pass through"
  }

  assert {
    condition     = module.vm["test-vm"].vm.network_device[0].bridge == "vmbr1"
    error_message = "Expected config.network_bridge to override the default"
  }

  assert {
    condition     = module.vm["test-vm"].vm.network_device[0].model == "e1000"
    error_message = "Expected config.network_model to override the default"
  }

  assert {
    condition     = module.vm["test-vm"].vm.serial_device[0].device == "/dev/ttyS0"
    error_message = "Expected config.serial_device to override the default"
  }

  assert {
    condition     = module.vm["test-vm"].vm.vga[0].type == "std"
    error_message = "Expected config.vga_type to override the default"
  }

  assert {
    condition     = tolist(module.vm["test-vm"].vm.boot_order) == tolist(["scsi0", "net0"])
    error_message = "Expected config.boot_order to override the default"
  }

  assert {
    condition     = module.vm["test-vm"].vm.scsi_hardware == "lsi"
    error_message = "Expected config.scsi_hardware to override the default"
  }

  assert {
    condition     = module.vm["test-vm"].vm.initialization[0].user_account[0].password == "s3cret"
    error_message = "Expected config.password to pass through"
  }

  assert {
    condition     = tolist(module.vm["test-vm"].vm.initialization[0].user_account[0].keys) == tolist(["ssh-ed25519 AAAATESTKEY"])
    error_message = "Expected config.ssh_pubkey to populate the SSH keys list"
  }
}

run "multiple_vms_created_independently" {
  command = plan

  variables {
    vms = {
      web-01 = {
        name = "web-01"
        ip   = "10.0.0.10"
        id   = 9100
        config = {
          target_node     = "pve1"
          template_id     = 9001
          agent           = true
          cores           = 2
          cpu_type        = "host"
          memory          = 2048
          storage_pool    = "local-lvm"
          storage_size_gb = 20
          storage_ssd     = true
          gateway         = "10.0.0.1"
          user            = "debian"
        }
      }
      db-01 = {
        name = "db-01"
        ip   = "10.0.0.20"
        id   = 9200
        config = {
          target_node     = "pve2"
          template_id     = 9001
          agent           = false
          cores           = 4
          cpu_type        = "x86-64-v2-AES"
          memory          = 8192
          storage_pool    = "local-lvm"
          storage_size_gb = 100
          storage_ssd     = false
          gateway         = "10.0.0.1"
          user            = "debian"
        }
      }
    }
  }

  assert {
    condition     = module.vm["web-01"].vm.node_name == "pve1" && module.vm["web-01"].vm.cpu[0].cores == 2
    error_message = "web-01 should keep its own node_name/cores, independent of db-01"
  }

  assert {
    condition     = module.vm["db-01"].vm.node_name == "pve2" && module.vm["db-01"].vm.cpu[0].cores == 4
    error_message = "db-01 should keep its own node_name/cores, independent of web-01"
  }

  assert {
    condition     = module.vm["db-01"].vm.agent[0].enabled == false
    error_message = "db-01's agent.enabled should be false as configured"
  }
}
