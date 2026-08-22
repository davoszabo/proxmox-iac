terraform {
  backend "s3" {}

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.92.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox.endpoint
  api_token = var.proxmox.api_token
  insecure  = var.proxmox.tls_insecure
}

variable "proxmox" { type = any }

variable "node_name" { type = string }

variable "template_id" { type = number }

variable "template_name" {
  type    = string
  default = "debian-13-genericcloud-agent"
}

variable "storage_pool" { type = string }

variable "iso_storage" {
  type        = string
  default     = "local"
  description = "Datastore that allows the Import (or ISO) content type, used to stage the qcow2."
}

variable "image_path" { type = string }

variable "disk_size" {
  type    = number
  default = 10
}

resource "proxmox_virtual_environment_file" "image" {
  content_type = "import"
  datastore_id = var.iso_storage
  node_name    = var.node_name
  overwrite    = true

  source_file {
    path      = var.image_path
    file_name = "${var.template_name}.qcow2"
  }
}

resource "proxmox_virtual_environment_vm" "template" {
  name      = var.template_name
  vm_id     = var.template_id
  node_name = var.node_name
  template  = true
  started   = false
  on_boot   = false
  bios      = "seabios"
  tags      = ["template", "debian-13"]
  keyboard_layout = "hu"

  agent {
    enabled = true
  }

  cpu {
    cores = 1
    type  = "host"
  }

  memory {
    dedicated = 1024
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  serial_device {
    device = "socket"
  }

  vga {
    type = "serial0"
  }

  disk {
    datastore_id = var.storage_pool
    import_from  = proxmox_virtual_environment_file.image.id
    interface    = "scsi0"
    size         = var.disk_size
    ssd          = true
    discard      = "on"
  }

  boot_order    = ["scsi0"]
  scsi_hardware = "virtio-scsi-pci"

  initialization {
    datastore_id = var.storage_pool
  }

  lifecycle {
    ignore_changes = [
      disk[0].import_from,
    ]
  }
}
