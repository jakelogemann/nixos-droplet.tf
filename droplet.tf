variable "vpc_uuid" {
  default = "a72ef278-d32a-4b07-8954-432f3890eb3d"
}

data "digitalocean_ssh_keys" "all" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

variable "domain" {
  default = "fnctl.io"
}

variable "node_name" {}
variable "region" {
  default = "nyc3"
}


variable "node_image" {
  default = "debian-11-x64"
}

variable "node_size" {
  default = "s-1vcpu-1gb-intel"
}

resource "digitalocean_droplet" "main" {
  image             = var.node_image
  name              = var.node_name
  region            = var.region
  vpc_uuid          = var.vpc_uuid
  size              = var.node_size
  ipv6              = true
  monitoring        = false
  backups           = false
  droplet_agent     = false
  graceful_shutdown = true
  user_data         = data.cloudinit_config.user_data.rendered
  ssh_keys          = data.digitalocean_ssh_keys.all.ssh_keys.*.id
  lifecycle {
    ignore_changes = [ssh_keys, tags]
  }
}

output "droplet" {
  value = merge(digitalocean_droplet.main, {
    domain     = var.domain
    ssh_keys   = join(",", digitalocean_droplet.main.ssh_keys)
    volume_ids = join(",", digitalocean_droplet.main.volume_ids)
    tags       = try(join(",", digitalocean_droplet.main.tags), null)
    commands = {
      ssh_v4 = try(format("ssh root@%s", digitalocean_droplet.main.ipv4_address), "N/A")
      ssh_v6 = try(format("ssh root@%s", digitalocean_droplet.main.ipv6_address), "N/A")
    }
  })
}
