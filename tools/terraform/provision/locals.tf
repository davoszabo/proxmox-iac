locals {
  vms = {
    for v in var.vms : v.name => v
  }
}
