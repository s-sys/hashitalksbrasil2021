terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "~> 0.6.11"
    }
  }
 required_version = ">= 0.13"
 experiments      = [module_variable_optional_attrs]
}

provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  # Exemplo 1
  # instances = { for vm in var.vms: vm.name => vm }

  # Exemplo 2
  instances = { for vm in var.vms : (substr(vm.name, 0, 3) == "tf-" ? vm.name : "tf-${vm.name}") => vm }
}

resource "libvirt_volume" "volume" {
  for_each = local.instances
  name     = "${each.key}.qcow2"
  #source  = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img"
  source   = "file:///data/isos/ubuntu-20.04-server-cloudimg-amd64.img"
  pool     = "VMs"
}

data "template_file" "user_data" {
  for_each = local.instances
  template = file("${path.module}/cloud_init.cfg")

  vars = {
    hostname = each.key
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  for_each       = local.instances
  name           = "cloudinit-${each.key}.iso"
  user_data      = data.template_file.user_data[each.key].rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_volume.volume[each.key].pool
}

resource "libvirt_domain" "vm" {
  for_each   = local.instances
  name       = each.key
  memory     = each.value.memory == null ? 640 : each.value.memory
  vcpu       = each.value.vcpu   == null ? 2   : each.value.vcpu
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.cloudinit[each.key].id
  depends_on = [libvirt_volume.volume]

  cpu {
    mode = "host-model"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.volume[each.key].id
    scsi      = true
  }

  graphics {
    type        = "spice"
    listen_type = "address"
  }
}
