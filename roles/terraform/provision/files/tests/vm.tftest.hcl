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
    condition     = module.vm["test-vm"].ip_address == "10.0.0.5/24"
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
    condition     = module.vm["test-vm"].ip_address == "10.0.0.5/26"
    error_message = "Expected config.ip_cidr = 26 to override the default"
  }
}
