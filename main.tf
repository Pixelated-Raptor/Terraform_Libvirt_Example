terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://pixelated@192.168.178.111/system?sshauth=privkey&keyfile=./id_libvirt_host"
}



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
  source = "https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "ubuntu_qcow2" {
  name           = "ubuntu_qcow2"
  pool           = libvirt_pool.ubuntu.name
  base_volume_id = libvirt_volume.ubuntu_base.id
  format         = "qcow2"
  size           = 20 * 1024 * 1024 * 1024
}

data "template_file" "user_data" {
  #template = file("${path.module}/cloud_init.cfg")
  template = file("${path.module}/cloud-inits/mein_cloud-init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config_guest.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.ubuntu.name
}


resource "libvirt_network" "my_net" {
  name = "my_net"
  mode = "bridge"
  #bridge = "virbr0"
  bridge = "br0"
}


resource "libvirt_domain" "ubuntu-vm" {
  name   = "ubuntu-tf"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_id = libvirt_network.my_net.id
    hostname   = "ubuntu-tf"
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
