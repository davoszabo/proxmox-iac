# variables.tf

variable "proxmox" { type = any } # or object(...)

# variable "proxmox_ssh" {
#   type = object({
#     username            = optional(string)
#     private_key_path    = optional(string)
#   })
# }

# `any`, not map(object({... config = any})): a map needs one common element type, so VMs with
# different VM_* key sets (e.g. memory_balloon_max on only some hosts) would fail to convert.
variable "vms" {
  type = any

  validation {
    condition = alltrue([
      for v in values(var.vms) : can(tostring(v.name)) && can(tostring(v.ip)) && can(tonumber(v.id)) && can(v.config.target_node)
    ])
    error_message = "Each VM needs name, ip, id and config.target_node (from ansible_host, vmid and VM_* vars)."
  }

  validation {
    condition = alltrue([
      for v in values(var.vms) : try(v.config.memory_balloon_max, v.config.memory) >= v.config.memory
    ])
    error_message = "VM_memory_balloon_max must be greater than or equal to VM_memory."
  }
}

