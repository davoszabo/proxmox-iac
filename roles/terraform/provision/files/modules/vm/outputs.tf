output "id" {
  value = proxmox_virtual_environment_vm.node.vm_id
}

output "ip_address" {
  value = proxmox_virtual_environment_vm.node.initialization[0].ip_config[0].ipv4[0].address
}
