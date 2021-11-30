variable "vms" {
  type = list(object({
    name   = string
    memory = optional(number)
    vcpu   = optional(number)
  }))
}
