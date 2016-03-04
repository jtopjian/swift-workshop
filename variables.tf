variable "ssh_public_key_location" {
  default = "/root/.ssh/id_rsa.pub"
}

variable "ssh_private_key_location" {
  default = "/root/.ssh/id_rsa"
}

variable "dns_nameserver" {
  default = "8.8.8.8"
}

variable "image_id" {
  default = "844492c0-b7e7-4ee5-b931-3dcca176060a"
}

variable "flavor_name" {
  default = "m1.large"
}
