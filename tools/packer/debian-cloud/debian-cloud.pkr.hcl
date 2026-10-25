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

variable "build_user" {
  type        = string
  default     = "packer"
  description = "Build-only SSH user created via cloud-init. Its authorized_keys is removed before the image is sealed."
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

variable "output_directory" {
  type        = string
  default     = "output"
  description = "Where the qcow2 is written. Must not exist yet unless `packer build -force` is used."
}

variable "packages" {
  type = list(string)
  default = [
    "qemu-guest-agent",
    "ca-certificates",
    "ufw",
    "chrony",
    "iotop",
    "nfs-common",
  ]
  description = "apt packages baked into the image. Must keep qemu-guest-agent: OpenTofu waits on it at clone time."

  validation {
    condition     = contains(var.packages, "qemu-guest-agent")
    error_message = "The packages list must include qemu-guest-agent, otherwise bpg/proxmox hangs waiting for the agent."
  }

  validation {
    condition     = alltrue([for p in var.packages : length(regexall("[,[:space:]]", p)) == 0])
    error_message = "Package names must not contain commas or whitespace."
  }
}

variable "services" {
  type        = list(string)
  default     = ["qemu-guest-agent", "chrony"]
  description = "systemd units enabled in the image."

  validation {
    condition     = alltrue([for s in var.services : length(regexall("[,[:space:]]", s)) == 0])
    error_message = "Service names must not contain commas or whitespace."
  }
}

source "qemu" "debian" {
  accelerator          = var.accelerator
  disk_image           = true
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  iso_target_extension = "qcow2"
  output_directory     = var.output_directory
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
  ssh_username         = var.build_user
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout          = "15m"
  boot_wait            = "5s"

  cd_label = "cidata"
  cd_content = {
    "user-data" = templatefile("${path.root}/templates/user-data.pkrtpl", {
      ssh_public_key = var.ssh_public_key
      build_user     = var.build_user
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
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    # Comma-joined: the default env_var_format single-quotes values inside the single-quoted
    # `sh -c '...'` above, so a value containing spaces would be split into separate words.
    environment_vars = [
      "TEMPLATE_TIMEZONE=${var.timezone}",
      "TEMPLATE_BUILD_USER=${var.build_user}",
      "TEMPLATE_PACKAGES=${join(",", var.packages)}",
      "TEMPLATE_SERVICES=${join(",", var.services)}",
    ]
    script = "${path.root}/scripts/provision.sh"
  }
}
