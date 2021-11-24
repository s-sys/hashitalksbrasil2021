output "hostnames" {
  value = libvirt_domain.vm[*].name
}

output "ips" {
  value = libvirt_domain.vm[*].network_interface[0].addresses
}
