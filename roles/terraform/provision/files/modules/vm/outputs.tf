output "vm" {
  description = "Full VM resource, minus deprecated attributes, for callers/tests that need to inspect any field without a dedicated output per attribute."
  value = {
    for k, v in proxmox_virtual_environment_vm.node : k => v
    if !contains(["timeout_move_disk"], k)
  }
}
