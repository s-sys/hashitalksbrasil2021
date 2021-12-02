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

variable "add_pub_ip" {
  description = "Add public IP to VMs."
  type        = bool
  default     = false
}

variable "pub_ip_persist" {
  description = "Set if public IP for VMs is Dynamic or Static."
  type        = bool
  default     = false
}

variable "add_boot_diag" {
  description = "Add boot diagnostics to VMs."
  type        = bool
  default     = true
}

variable "vm_count" {
  description = "Number of VMs to instanciate."
  type        = number
  default     = 1
}

variable "vm_image" {
  description = "String with data about image to use."
  type        = string
  default     = "Canonical:0001-com-ubuntu-minimal-focal-daily:minimal-20_04-daily-lts-gen2:latest"
}

variable "vm_name_prefix" {
  description = "Name prefix for VM name."
  type        = string
  default     = "instance"
}

variable "vm_size" {
  description = "Azure size for VM."
  type        = string
  default     = "Standard_B1ms"
}

variable "vm_disk_type" {
  description = "Azure disk size for VM."
  type        = string
  default     = "Standard_LRS"
}

variable "vm_disk_size" {
  description = "Azure attached disk size for VM."
  type        = string
  default     = ""
}

variable "vm_net_accel" {
  description = "Azure network acceleration for VM."
  type        = bool
  default     = true
}

variable "cloudinit" {
  description = "Azure cloudinit file for VM."
  type        = string
  default     = "files/cloud-init.yaml"
}

variable "vm_swap_size" {
  description = "Azure swap size for VM."
  type        = string
  default     = "2048"
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
  default = {
    activity = ""
  }
}
