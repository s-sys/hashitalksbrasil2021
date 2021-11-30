output "virtual_machines" {
  value = tomap({
    for k, j in libvirt_domain.vm[*]: j.name => element(j.network_interface[0].addresses, 0)
  })
}
