mock_provider "proxmox" {}

variables {
  proxmox = {
    endpoint     = "https://proxmox.example.com:8006"
    api_token    = "user@pve!token=fake"
    tls_insecure = true
  }
  node_name    = "pve1"
  template_id  = 9001
  storage_pool = "local-lvm"
  image_path   = "/var/lib/packer/debian-13-genericcloud-agent.qcow2"
}

run "defaults_apply" {
  command = plan

  # The mock provider's auto-generated id for the uploaded file doesn't
  # match the "datastore:iso/file.img" format the VM resource's
  # import_from validation expects - override it with a valid one.
  override_resource {
    target = proxmox_virtual_environment_file.image
    values = {
      id = "local:iso/debian-13-genericcloud-agent.qcow2"
    }
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.name == "debian-13-genericcloud-agent"
    error_message = "Expected default template_name"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.vm_id == 9001
    error_message = "Expected vm_id to come from var.template_id"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.node_name == "pve1"
    error_message = "Expected node_name to come from var.node_name"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.template == true
    error_message = "This resource must be marked as a template"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.started == false && proxmox_virtual_environment_vm.template.on_boot == false
    error_message = "A template should not be started or start on boot"
  }

  assert {
    condition     = tolist(proxmox_virtual_environment_vm.template.tags) == tolist(["template", "debian-13"])
    error_message = "Expected fixed template tags"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.disk[0].size == 10
    error_message = "Expected default disk_size of 10"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.disk[0].datastore_id == "local-lvm"
    error_message = "Expected disk datastore_id to come from var.storage_pool"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.disk[0].import_from == proxmox_virtual_environment_file.image.id
    error_message = "Expected the template disk to import from the uploaded image"
  }

  assert {
    condition     = proxmox_virtual_environment_file.image.datastore_id == "local"
    error_message = "Expected default iso_storage of 'local'"
  }

  assert {
    condition     = proxmox_virtual_environment_file.image.source_file[0].file_name == "debian-13-genericcloud-agent.qcow2"
    error_message = "Expected uploaded file name to be derived from template_name"
  }
}

run "overrides_apply" {
  command = plan

  variables {
    template_name = "debian-13-custom"
    disk_size     = 40
    iso_storage   = "nfs-import"
  }

  override_resource {
    target = proxmox_virtual_environment_file.image
    values = {
      id = "nfs-import:iso/debian-13-custom.qcow2"
    }
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.name == "debian-13-custom"
    error_message = "Expected config template_name to override the default"
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.disk[0].size == 40
    error_message = "Expected config disk_size to override the default"
  }

  assert {
    condition     = proxmox_virtual_environment_file.image.datastore_id == "nfs-import"
    error_message = "Expected config iso_storage to override the default"
  }

  assert {
    condition     = proxmox_virtual_environment_file.image.source_file[0].file_name == "debian-13-custom.qcow2"
    error_message = "Expected uploaded file name to follow the overridden template_name"
  }
}

# Rebuild path: first apply, then a change that replaces the uploaded file must also replace the
# template VM (replace_triggered_by). tofu test cannot assert on planned actions, so the plan below
# is checked by running `tofu test -verbose` and looking for "replace_triggered_by" on the VM.
run "rebuild_initial" {
  command = apply

  override_resource {
    target = proxmox_virtual_environment_file.image
    values = {
      id = "local:import/debian-13-genericcloud-agent.qcow2"
    }
  }
}

run "rebuild_replaces_template" {
  command = plan

  variables {
    template_name = "debian-13-rebuilt"
  }

  override_resource {
    target = proxmox_virtual_environment_file.image
    values = {
      id = "local:import/debian-13-rebuilt.qcow2"
    }
  }

  assert {
    condition     = proxmox_virtual_environment_vm.template.disk[0].import_from == "local:import/debian-13-rebuilt.qcow2"
    error_message = "Expected the recreated template to import the newly uploaded image"
  }
}
