resource "openstack_compute_keypair_v2" "swift_key" {
  name = "swift_key"
  public_key = "${file(var.ssh_public_key_location)}"
}

resource "openstack_networking_network_v2" "private" {
  name = "private"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "private" {
  name = "private"
  network_id = "${openstack_networking_network_v2.private.id}"
  cidr = "192.168.1.0/24"
  gateway_ip = "192.168.1.10"
  dns_nameservers = ["${var.dns_nameserver}"]

  ip_version = 4
}

resource "openstack_compute_secgroup_v2" "allow_all" {
  name = "allow_all"
  description = "allow all traffic"
  rule {
    from_port = -1
    to_port = -1
    ip_protocol = "icmp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 1
    to_port = 65535
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 1
    to_port = 65535
    ip_protocol = "udp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_compute_instance_v2" "swift" {
  name = "swift"
  security_groups = ["${openstack_compute_secgroup_v2.allow_all.name}"]
  key_pair = "swift_key"
  image_id = "${var.image_id}"
  flavor_name = "${var.flavor_name}"

  network {
    name = "default"
  }

  network {
    uuid = "${openstack_networking_network_v2.private.id}"
    fixed_ip_v4 = "192.168.1.10"
  }

  depends_on = ["openstack_networking_subnet_v2.private"]
}

resource "null_resource" "sleep" {
  provisioner "local-exec" {
    command = "sleep 20"
  }

  depends_on = ["openstack_compute_instance_v2.swift", "openstack_compute_instance_v2.storage"]
}

resource "null_resource" "swift" {
  connection {
    user = "ubuntu"
    host = "${openstack_compute_instance_v2.swift.access_ip_v6}"
    private_key = "${file(var.ssh_private_key_location)}"
  }

  provisioner "file" {
    source = "/root/.ssh/id_rsa"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "file" {
    source = "files"
    destination = "/home/ubuntu/files"
  }

  provisioner "remote-exec" {
    inline = ["sudo bash /home/ubuntu/files/swift_proxy.sh"]
  }

  depends_on = ["null_resource.sleep"]
}

resource "openstack_blockstorage_volume_v1" "storage" {
  count = 3
  name = "${format("storage-%02d", count.index+1)}"
  size = 1
}

resource "openstack_compute_instance_v2" "storage" {
  count = 3
  name = "${format("storage-%02d", count.index+1)}"
  security_groups = ["${openstack_compute_secgroup_v2.allow_all.name}"]
  key_pair = "swift_key"
  image_id = "${var.image_id}"
  flavor_name = "${var.flavor_name}"

  network {
    uuid = "${openstack_networking_network_v2.private.id}"
    fixed_ip_v4 = "${format("192.168.1.%d", count.index+101)}"
  }

  volume {
    volume_id = "${element(openstack_blockstorage_volume_v1.storage.*.id, count.index)}"
  }
}

resource "null_resource" "storage" {
  count = 3
  connection {
    user = "ubuntu"
    host = "${element(openstack_compute_instance_v2.storage.*.access_ip_v4, count.index)}"
    private_key = "${file(var.ssh_private_key_location)}"
    bastion_host = "${openstack_compute_instance_v2.swift.access_ip_v6}"
    bastion_user = "ubuntu"
  }

  provisioner "file" {
    source = "files"
    destination = "/home/ubuntu/files"
  }

  provisioner "remote-exec" {
    inline = ["sudo bash /home/ubuntu/files/swift_node.sh"]
  }

  provisioner "remote-exec" {
    connection {
      user = "ubuntu"
      host = "${openstack_compute_instance_v2.swift.access_ip_v6}"
      private_key = "${file(var.ssh_private_key_location)}"
    }
    inline = ["sudo bash /home/ubuntu/files/push_rings.sh"]
  }

  depends_on = ["null_resource.sleep", "null_resource.swift"]
}
