variable "subscription_id" {
  description = "Subscriptions ID to be used."
  type        = string
  default     = ""
}

variable "client_id" {
  description = "Client ID from Azure."
  type        = string
  default     = ""
}

variable "client_secret" {
  description = "Client secret from Azure."
  type        = string
  default     = ""
}

variable "tenant_id" {
  description = "Tenant ID from Azure."
  type        = string
  default     = ""
}

variable "resource_group" {
  description = "Resource group name to create."
  type        = string
  default     = ""
}

variable "location" {
  description = "Location where resources should be created."
  type        = string
  default     = "centralus"
}

variable "admin_username" {
  description = "Name for the admin user."
  type        = string
  default     = "azureroot"
}

variable "admin_password" {
  description = "Password for admin user."
  type        = string
  default     = "Passw0rd"
}

variable "vnet_name" {
  description = "Name of virtual network for VMs."
  type        = string
  default     = ""
}

variable "vnet_addr" {
  description = "Network address for virtual network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_name" {
  description = "Name of virtual subnet."
  type        = string
  default     = ""
}

variable "subnet_addr" {
  description = "Network address Name of virtual subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "storage_account" {
  description = "Storage to use for VMs."
  type        = string
  default     = "storage:rg"
}

variable "storage_tier" {
  description = "Storage tier to create storage account."
  type        = string
  default     = "Standard"
}

variable "storage_repl" {
  description = "Storage replication type to create storage account."
  type        = string
  default     = "LRS"
}

variable "nsg_name" {
  description = "Network security group name."
  type        = string
  default     = ""
}

variable "nsg_rules" {
  description = "Network Security Group Rules."
  type        = map(any)
  default = {
    name                       = ""
    direction                  = ""
    access                     = ""
    protocol                   = ""
    source_port_range          = ""
    destination_port_range     = ""
    source_address_prefix      = ""
    destination_address_prefix = ""
  }
}

variable "tags" {
  description = "Tags for resources."
  type        = map(any)
  default = {}
}

variable "vms" {
  description = "List of VMs to create"
  type             = list(object({
    name           = string
    size           = string
    image          = object({
      publisher    = string
      offer        = string
      sku          = string
      version      = string
    })
    add_pub_ip     = bool
    pub_ip_persist = bool
    add_boot_diag  = bool
    disk_type      = string
    add_extra_disk = bool
    disk_size      = number
    net_accel      = bool
    cloudinit      = string
    swap_size      = number
    })
  )
}
