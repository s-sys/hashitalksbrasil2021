output "public_ips" {
  description = "Public IP of network interface of VMs"
  value       = {
                  for k, v in azurerm_public_ip.my_public_ip
                    : k => v.ip_address
                }
}

output "private_ips" {
  description = "Private IP of network interface of VMs"
  value       = {
                  for k, v in azurerm_network_interface.my_network_interface_vm
                    : k => element(v.private_ip_addresses, 0)
                }
}
