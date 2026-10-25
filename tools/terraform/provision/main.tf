module "vm" {
  source   = "./modules/vm"
  for_each = local.vms

  vm_id  = each.value.id
  name   = each.value.name
  ip     = each.value.ip
  config = each.value.config
}
