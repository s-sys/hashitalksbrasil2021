output "public_ips" {
  description = "Public IP of network interface of VMs"
  value       = tomap({
    for k, j in azurerm_public_ip.my_public_ip: j.name => j.ip_address
  })
}

output "private_ips" {
  description = "Private IP of network interface of VMs"
  value       = tomap({
    for k, j in azurerm_network_interface.my_network_interface_vm: j.name => element(j.private_ip_addresses, 0)
  })
}
