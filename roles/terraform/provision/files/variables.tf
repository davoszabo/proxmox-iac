# variables.tf

variable "proxmox" { type = any } # or object(...)

# variable "proxmox_ssh" {
#   type = object({
#     username            = optional(string)
#     private_key_path    = optional(string)
#   })
# }

variable "vms" {
  type = map(object({
    name   = string
    ip     = string
    id     = number
    config = any
  }))
}

