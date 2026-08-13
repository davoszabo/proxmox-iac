terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.92.0"
    }
  }
}

provider "proxmox" {
  endpoint          = var.proxmox.endpoint
  api_token         = var.proxmox.api_token
  insecure          = var.proxmox.tls_insecure
  # ssh {
  #   username = var.proxmox_ssh.username
  #
  #   # Use agent only when private key is NOT defined
  #   agent    = (var.proxmox_ssh.private_key_path == null || trimspace(var.proxmox_ssh.private_key_path) == "")

  #   # Get the private key if specified
  #   private_key = (
  #     var.proxmox_ssh.private_key_path != null && trimspace(var.proxmox_ssh.private_key_path) != ""
  #     ? file(var.proxmox_ssh.private_key_path)
  #     : null
  #   )
  # }
}

