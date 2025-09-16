variable "libvirt_connection_uri" {
  description = "uri to connect to a libvirt host."
  type        = string
  default     = "qemu+ssh://pixelated@192.168.178.111/system?sshauth=privkey&keyfile=./id_libvirt_host"
}

variable "cloud_image_ubuntu-22_04" {
  description = "url to download an ubuntu 22.04 amd64 cloud image."
  type        = string
  default     = "https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-amd64.img"
}

variable "libvirt_volume_disk_size" {
  description = "Size of the main disk available to the vm. The cloud-init file should resize the root partition automatically to use the full space."
  type        = number
  default     = 20 * 1024 * 1024 * 1024
}

variable "path_to_cloud-init_file" {
  description = "Path to the cloud-init file to be used by the vm."
  type        = string
  default     = "cloud-inits/mein_cloud-init.cfg"
}

variable "path_network_config_guest" {
  description = "Path to the network config (netplan) used by the vm."
  type        = string
  default     = "network_config_guest.cfg"
}

variable "guest_number_vcpus" {
  description = "Number of virtual cpu core available to the vm."
  type        = number
  default     = 6
}

variable "guest_memory" {
  description = "How much ram is allocated to the vm in MiB."
  type        = string
  default     = "16384"
}

variable "guest_hostname" {
  description = "Network hostname of the guest."
  type        = string
  default     = "ubuntu-tf"
}
