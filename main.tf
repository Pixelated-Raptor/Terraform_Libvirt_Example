# Providers
terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}



# Connection to libvirt host
provider "libvirt" {
  uri = var.libvirt_connection_uri
}



# Guest storage
resource "libvirt_pool" "ubuntu" {
  name = "ubuntu"
  type = "dir"

  target {
    path = "/tmp/tf-provider-libvirt-pool-ubuntu"
  }
}

resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu_base"
  pool   = libvirt_pool.ubuntu.name
  source = var.cloud_image_ubuntu-22_04
  format = "qcow2"
}

resource "libvirt_volume" "ubuntu_qcow2" {
  name           = "ubuntu_qcow2"
  pool           = libvirt_pool.ubuntu.name
  base_volume_id = libvirt_volume.ubuntu_base.id
  format         = "qcow2"
  size           = var.libvirt_volume_disk_size
}



# Loading guest OS config via cloud-init 
data "template_file" "user_data" {
  template = file("${path.module}/${var.path_to_cloud-init_file}")
}



# Loading guest OS network config via netplan
data "template_file" "network_config" {
  template = file("${path.module}/${var.path_network_config_guest}")
}



# Injecting above into guest storage pool
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.ubuntu.name
}



# Networkinterfacing for the guest
resource "libvirt_network" "my_net" {
  name   = "my_net"
  mode   = "bridge"
  bridge = "br0"
}



# Creating the actual vm
resource "libvirt_domain" "ubuntu-vm" {
  name   = "ubuntu-tf"
  memory = var.guest_memory
  vcpu   = var.guest_number_vcpus

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  cpu {
    mode = "host-passthrough"
  }

  # OpenStack requieres two network interfaces. Only one of the needs to be
  # connected to the outside and the other is going to be managed entirely
  # by OpenStack networking service
  network_interface {
    network_id = libvirt_network.my_net.id
    hostname   = var.guest_hostname
  }

  network_interface {
    network_id     = libvirt_network.my_net.id
    wait_for_lease = false
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  disk {
    volume_id = libvirt_volume.ubuntu_qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
