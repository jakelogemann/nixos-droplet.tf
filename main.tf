terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.32"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }
}

locals {
  ssh_username = "root"
  ipv4_address = var.floating_ip ? digitalocean_floating_ip.main[0].ip_address : digitalocean_droplet.main.ipv4_address
}

resource "digitalocean_droplet" "main" {
  backups           = var.backups
  droplet_agent     = false
  graceful_shutdown = var.graceful_shutdown
  image             = var.image
  ipv6              = var.ipv6
  monitoring        = false
  name              = var.hostname
  region            = var.region
  resize_disk       = var.resize_disk
  size              = var.droplet_size
  ssh_keys          = length(var.ssh_key_ids) != 0 ? var.ssh_key_ids : data.digitalocean_ssh_keys.all.ssh_keys.*.id
  tags              = length(var.droplet_tags) != 0 ? var.droplet_tags : ["nixos"]
  user_data         = data.cloudinit_config.user_data.rendered
  volume_ids        = var.volume_ids
  vpc_uuid          = data.digitalocean_vpc.main.id
  lifecycle {
    ignore_changes = [ssh_keys]
  }
}

resource "digitalocean_floating_ip" "main" {
  count      = var.floating_ip ? 1 : 0
  droplet_id = digitalocean_droplet.main.id
  region     = digitalocean_droplet.main.region
}
