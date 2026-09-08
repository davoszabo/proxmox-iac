module "vm" {
  source   = "./modules/vm"
  for_each = local.vms

  vm_id  = each.value.id
  name   = each.value.name
  ip     = each.value.ip
  config = each.value.config
}

moved {
  from = proxmox_virtual_environment_vm.node
  to   = module.vm.proxmox_virtual_environment_vm.node
}
