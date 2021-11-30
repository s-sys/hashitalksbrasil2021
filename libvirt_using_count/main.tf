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
  instances = [for i in var.vms : (substr(i.name, 0, 3) == "tf-" ? i.name : "tf-${i.name}")]
  num_vms   = length(local.instances)
}

resource "libvirt_volume" "volume" {
  count   = local.num_vms 
  name    = "${local.instances[count.index]}.qcow2"
  #source = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.img"
  source  = "file:///data/isos/ubuntu-20.04-server-cloudimg-amd64.img"
  pool    = "VMs"
}

data "template_file" "user_data" {
  count    = local.num_vms
  template = file("${path.module}/cloud_init.cfg")

  vars = {
    hostname = local.instances[count.index]
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  count          = local.num_vms
  name           = "cloudinit-${local.instances[count.index]}.iso"
  user_data      = data.template_file.user_data[count.index].rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_volume.volume[count.index].pool
}

resource "libvirt_domain" "vm" {
  count      = local.num_vms
  name       = local.instances[count.index]
  memory     = var.vms[count.index].memory == null ? 640 : var.vms[count.index].memory
  vcpu       = var.vms[count.index].vcpu   == null ? 2   : var.vms[count.index].vcpu
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.cloudinit[count.index].id
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
    volume_id = libvirt_volume.volume[count.index].id
    scsi      = true
  }

  graphics {
    type        = "spice"
    listen_type = "address"
  }
}
