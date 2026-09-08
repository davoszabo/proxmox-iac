packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1.1"
    }
  }
}

variable "ssh_public_key" {
  type        = string
  description = "Throwaway public key for this build only. Not baked into the finished image."
}

variable "ssh_private_key_file" {
  type        = string
  description = "Path to the matching throwaway private key."
}

variable "timezone" {
  type    = string
  default = "Europe/Budapest"
}

variable "accelerator" {
  type        = string
  default     = "kvm"
  description = "qemu accelerator: kvm (preferred) or none (TCG, slow)."
}

variable "iso_url" {
  type    = string
  default = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}

variable "iso_checksum" {
  type    = string
  default = "file:https://cloud.debian.org/images/cloud/trixie/latest/SHA512SUMS"
}

variable "disk_size" {
  type    = string
  default = "10G"
}

source "qemu" "debian" {
  accelerator          = var.accelerator
  disk_image           = true
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  iso_target_extension = "qcow2"
  output_directory     = "output"
  vm_name              = "debian-13-genericcloud-agent.qcow2"
  format               = "qcow2"
  disk_size            = var.disk_size
  disk_compression     = true
  disk_interface       = "virtio"
  net_device           = "virtio-net"
  memory               = 2048
  cpus                 = 2
  headless             = true
  shutdown_command     = "sudo shutdown -P now"
  ssh_username         = "debian"
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "15m"
  boot_wait            = "5s"

  cd_label = "cidata"
  cd_content = {
    "user-data" = templatefile("${path.root}/templates/user-data.pkrtpl", {
      ssh_public_key = var.ssh_public_key
    })
    "meta-data" = "instance-id: packer-debian-cloud\nlocal-hostname: debian\n"
  }
}

build {
  sources = ["source.qemu.debian"]

  provisioner "file" {
    source      = "${path.root}/certs"
    destination = "/tmp"
  }

  provisioner "shell" {
    execute_command   = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    environment_vars  = ["TEMPLATE_TIMEZONE=${var.timezone}"]
    script            = "${path.root}/scripts/provision.sh"
  }
}
