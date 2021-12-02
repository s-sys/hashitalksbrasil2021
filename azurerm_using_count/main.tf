# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

# Get Azure subscription
data "azurerm_subscription" "current" {
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id == "" ? null : var.subscription_id
  tenant_id       = var.tenant_id       == "" ? null : var.client_secret
  client_id       = var.client_id       == "" ? null : var.client_id
  client_secret   = var.client_secret   == "" ? null : var.client_secret
}

provider "azurerm" {
  features {}
  
  alias           = "dns"
  subscription_id = var.dns_subscription_id == "" ? null : var.dns_subscription_id
  tenant_id       = var.dns_tenant_id       == "" ? null : var.dns_tenant_id
  client_id       = var.dns_client_id       == "" ? null : var.dns_client_id
  client_secret   = var.dns_client_secret   == "" ? null : var.dns_client_secret
}

locals {
  # Azure defaults
  resource_group      = (
                        var.resource_group != "" 
                        ? data.azurerm_resource_group.my_resource_group[0].name
                        : azurerm_resource_group.my_resource_group[0].name
                        )
  default_location    = (
                          var.resource_group != ""
                          ? data.azurerm_resource_group.my_resource_group[0].location
                          : var.location
                        )
  default_vnet_name   = (
                          var.vnet_name != ""
                          ? data.azurerm_virtual_network.my_virtual_network[0].name
                          : azurerm_virtual_network.my_virtual_network[0].name
                        )
  default_subnet_id   = (
                          var.subnet_name != ""
                          ? data.azurerm_subnet.my_subnet[0].id
                          : azurerm_subnet.my_subnet[0].id
                        )

  # Storage account
  storage_data         = split(":", var.storage_account)
  storage_account      = local.storage_data[0]
  storage_rg           = local.storage_data[1]
  default_storage_name = local.storage_account != "" ? local.storage_account : "diag${random_id.randomId.hex}"

  # NSG
  nsg_size                       = length(var.nsg_rules["name"]) > 0 ? length(split(",", var.nsg_rules["name"])) : 0
  nsg_rule_name                  = local.nsg_size > 0 ? ([for name in split(",", var.nsg_rules["name"]) : trimspace(name)]) : null
  nsg_direction                  = local.nsg_size > 0 ? ([for direction in split(",", var.nsg_rules["direction"]) : trimspace(direction)]) : null
  nsg_access                     = local.nsg_size > 0 ? ([for access in split(",", var.nsg_rules["access"]) : trimspace(access)]) : null
  nsg_protocol                   = local.nsg_size > 0 ? ([for protocol in split(",", var.nsg_rules["protocol"]) : trimspace(protocol)]) : null
  nsg_source_port_range          = local.nsg_size > 0 ? ([for source_port_range in split(",", var.nsg_rules["source_port_range"]) : trimspace(source_port_range)]) : null
  nsg_destination_port_range     = local.nsg_size > 0 ? ([for destination_port_range in split(",", var.nsg_rules["destination_port_range"]) : trimspace(destination_port_range)]) : null
  nsg_source_address_prefix      = local.nsg_size > 0 ? ([for source_address_prefix in split(",", var.nsg_rules["source_address_prefix"]) : trimspace(source_address_prefix)]) : null
  nsg_destination_address_prefix = local.nsg_size > 0 ? ([for destination_address_prefix in split(",", var.nsg_rules["destination_address_prefix"]) : trimspace(destination_address_prefix)]) : null
  nsg_priority_base              = 1000

  # VMs
  vm_count     = var.vm_count == null ? 1 : var.vm_count
  vm_names     = {for i in range(local.vm_count): i => format("%s-%02d", var.vm_name_prefix, i + 1)}
  vm_size      = var.vm_size      == null ? "Standard_D2_v3" : var.vm_size
  vm_disk_type = var.vm_disk_type == null ? "Standard_LRS"   : var.vm_disk_type
  vm_disk_size = var.vm_disk_size == ""   ? 100              : var.vm_disk_size
  publisher    = length(split(":", var.vm_image)) != 4 ? "Canonical" : split(":", var.vm_image)[0]
  offer        = length(split(":", var.vm_image)) != 4 ? "0001-com-ubuntu-minimal-focal-daily" : split(":", var.vm_image)[1]
  sku          = length(split(":", var.vm_image)) != 4 ? "minimal-20_04-daily-lts-gen2" : split(":", var.vm_image)[2]
  version      = length(split(":", var.vm_image)) != 4 ? "latest" : split(":", var.vm_image)[3]
  vm_net_accel = var.vm_net_accel == null ? true : tobool(var.vm_net_accel)
}

# Set cloud-init file to run
data "template_file" "config" {
  template = file(var.cloudinit)

  vars = {
    vm_swap_size   = var.vm_swap_size
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.config.rendered
  }
}

data "azurerm_resource_group" "my_resource_group" {
  count = var.resource_group != "" ? 1 : 0
  name  = var.resource_group
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "my_resource_group" {
  count    = var.resource_group != "" ? 0 : 1
  name     = "hashitalks-azure-count"
  location = local.default_location
  tags     = var.tags
}

# Use existing virtual network
data "azurerm_virtual_network" "my_virtual_network" {
  count               = var.vnet_name != "" ? 1 : 0
  name                = var.vnet_name
  resource_group_name = local.resource_group
}

# Create virtual network
resource "azurerm_virtual_network" "my_virtual_network" {
  count               = var.vnet_name != "" ? 0 : 1
  name                = "vnet"
  address_space       = [var.vnet_addr]
  location            = local.default_location
  resource_group_name = local.resource_group
  tags                = var.tags
}

# Use existing subnet network
data "azurerm_subnet" "my_subnet" {
  count                = var.subnet_name != "" ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = local.resource_group
  virtual_network_name = local.default_vnet_name
}

# Create subnet
resource "azurerm_subnet" "my_subnet" {
  count                = var.subnet_name != "" ? 0 : 1
  name                 = "subnet"
  resource_group_name  = local.resource_group
  virtual_network_name = local.default_vnet_name
  address_prefixes     = [var.subnet_addr]
}

# Create public IPs for VMs
resource "azurerm_public_ip" "my_public_ip" {
  count               = (
                          local.vm_count > 0
                            && tobool(var.add_pub_ip) == true
                          ? local.vm_count
                          : 0
                        )
  name                = format("%s-%02d_public_ip", var.vm_name_prefix, count.index + 1)
  location            = local.default_location
  resource_group_name = local.resource_group
  allocation_method   = tobool(var.pub_ip_persist) == true ? "Static" : "Dynamic"
  tags                = var.tags
}

# Create Network Security Group
data "azurerm_network_security_group" "my_nsg" {
  count               = length(var.nsg_name) > 0 ? 1 : 0
  name                = var.nsg_name
  resource_group_name = local.resource_group
}

resource "azurerm_network_security_group" "my_nsg" {
  count               = length(var.nsg_name) > 0 ? 0 : 1
  name                = "nsg"
  location            = local.default_location
  resource_group_name = local.resource_group
  tags                = var.tags
}

# Create Network Security rules
resource "azurerm_network_security_rule" "my_nsg_rule" {
  count                       = local.nsg_size > 0 ? local.nsg_size : 0
  name                        = local.nsg_rule_name[count.index]
  priority                    = local.nsg_priority_base + count.index
  direction                   = local.nsg_direction[count.index]
  access                      = local.nsg_access[count.index]
  protocol                    = local.nsg_protocol[count.index]
  source_port_range           = local.nsg_source_port_range[count.index]
  destination_port_range      = local.nsg_destination_port_range[count.index]
  source_address_prefix       = local.nsg_source_address_prefix[count.index]

  destination_address_prefix  = local.nsg_destination_address_prefix[count.index]
  resource_group_name         = local.resource_group
  network_security_group_name = (
                                  length(var.nsg_name) > 0
                                  ? data.azurerm_network_security_group.my_nsg[0].name
                                  : azurerm_network_security_group.my_nsg[0].name
                                )
}

# Create network interface for VMs
resource "azurerm_network_interface" "my_network_interface_vm" {
  count                         = local.vm_count > 0 ? local.vm_count : 0
  name                          = format("%s-%02d_nic", var.vm_name_prefix, count.index + 1)
  location                      = local.default_location
  resource_group_name           = local.resource_group
  enable_accelerated_networking = local.vm_net_accel
  tags                          = var.tags

  ip_configuration {
    name                          = "nic_configuration_${count.index + 1}"
    subnet_id                     = local.default_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = (
                                      tobool(var.add_pub_ip) == true
                                      ? azurerm_public_ip.my_public_ip[count.index].id
                                      : null
                                    )
  }
}

resource "azurerm_network_interface_security_group_association" "my_network_nsg_association" {
  count                     = local.vm_count > 0 ? local.vm_count : 0
  network_interface_id      = azurerm_network_interface.my_network_interface_vm[count.index].id
  network_security_group_id = (
                                length(var.nsg_name) > 0
                                ? data.azurerm_network_security_group.my_nsg[0].id
                                : azurerm_network_security_group.my_nsg[0].id
                              )
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    resource_group = local.resource_group
  }

  byte_length = 8
}

# Use existing storage account
data "azurerm_storage_account" "my_storage_account" {
  count               = (
                          local.storage_account != ""
                            && local.storage_rg != ""
                          ? 1
                          : 0
                        )
  name                = local.storage_account
  resource_group_name = local.storage_rg
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  count                    = (
                               local.vm_count > 0
                                 && tobool(var.add_boot_diag) == true
                                 && local.storage_account == ""
                                 && local.storage_rg == ""
                               ? 1 : 0
                             )
  name                     = local.default_storage_name
  resource_group_name      = local.resource_group
  location                 = local.default_location
  account_tier             = var.storage_tier
  account_replication_type = var.storage_repl
  tags                     = var.tags
}

# Aditional disk
resource "azurerm_managed_disk" "vm_extra_disk" {
  count                = (
                           local.vm_count > 0
                             && tonumber(var.vm_disk_size) > 0
                           ? local.vm_count
                           : 0
                         )
  name                 = format("%s-%02d_data_disk", var.vm_name_prefix, count.index + 1)
  location             = local.default_location
  resource_group_name  = local.resource_group
  storage_account_type = local.vm_disk_type
  create_option        = "Empty"
  disk_size_gb         = local.vm_disk_size
  depends_on           = [azurerm_linux_virtual_machine.vm]
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm_extra_disk_attach" {
  count              = (
                         local.vm_count > 0
                           && tonumber(var.vm_disk_size) > 0
                         ? local.vm_count
                         : 0
                       )
  managed_disk_id    = azurerm_managed_disk.vm_extra_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm[count.index].id
  lun                = 1
  caching            = "ReadWrite"
}

# Create virtual machine instances
resource "azurerm_linux_virtual_machine" "vm" {
  count                           = local.vm_count
  name                            = local.vm_names[count.index]
  location                        = local.default_location
  resource_group_name             = local.resource_group
  network_interface_ids           = [azurerm_network_interface.my_network_interface_vm[count.index].id]
  size                            = local.vm_size
  custom_data                     = data.template_cloudinit_config.config.rendered
  computer_name                   = local.vm_names[count.index]
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  tags                            = var.tags

  os_disk {
    name                 = format("%s_os_disk", local.vm_names[count.index])
    caching              = "ReadWrite"
    storage_account_type = local.vm_disk_type
  }

  source_image_reference {
    publisher = local.publisher
    offer     = local.offer
    sku       = local.sku
    version   = local.version
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  boot_diagnostics {
    storage_account_uri = (
                            tobool(var.add_boot_diag) == true
                            ? (local.storage_account != ""
                                ? data.azurerm_storage_account.my_storage_account[0].primary_blob_endpoint
                                : azurerm_storage_account.my_storage_account[0].primary_blob_endpoint
                              )
                            : null
                          )
  }
}
