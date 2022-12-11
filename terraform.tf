terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.2"
    }
  }
}

locals {
  ipv4_addresses = var.floating_ip ? digitalocean_floating_ip.main.*.ip_address : digitalocean_droplet.main.*.ipv4_address
  ssh_command    = "ssh -oRequestTTY=yes -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=accept-new"
}

output "ssh_commands" {
  value = formatlist("%s root@%s", local.ssh_command, local.ipv4_addresses)
}

variable "floating_ip" {
  default = false
  type    = bool
}

variable "external_volumes" {
  default = false
  type    = bool
}

variable "host_count" {
  default = 1
  type    = number
}

variable "nix_channel" {
  default = "nixos-unstable"
  type    = string
}

variable "infect_script" {
  default = "https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect"
  type    = string
}

variable "node_name" {
  default = "nixlet"
  type    = string
}

variable "domain" {
  default = "polis.dev"
  type    = string
}

variable "region" {
  default = "nyc3"
  type    = string
}

variable "node_image" {
  default = "debian-11-x64"
  type    = string
}

variable "node_size" {
  default = "s-1vcpu-1gb-intel"
  type    = string
}

data "digitalocean_ssh_keys" "all" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

data "digitalocean_vpc" "default" {
  name = "default-${var.region}"
}

data "cloudinit_config" "user_data" {
  count         = var.host_count
  gzip          = false
  base64_encode = false

  part {
    filename     = "bootstrap.yml"
    content_type = "text/cloud-config"
    content = yamlencode({

      # Create nix install group
      groups = ["nixbld"]

      # Create nix install users
      users = [
        for id in range(0, 9) : {
          name          = "nixbld${id}"
          no_user_group = true
          system        = true
          gecos         = "Nix build user ${id}"
          primary_group = "nixbld"
          groups        = ["nixbld"]
        }
      ]

      # Write nixos files
      write_files = [{

        # System-wide nixos configuration
        path        = "/etc/nixos/system.nix"
        permissions = "0644"
        content     = file("system.nix")
        }, {

        # System-wide nix configuration
        path        = "/etc/nix/nix.conf"
        permissions = "0644"
        content     = <<-NIX_CONF
          allow-dirty = true
          allowed-users = root
          auto-optimise-store = true
          build-users-group = nixbld
          download-attempts = 3
          enforce-determinism = true
          eval-cache = true
          experimental-features = nix-command flakes ca-derivations
          http-connections = 50
          log-lines = 30
          system-features = kvm
          trusted-users = root
          warn-dirty = false
        NIX_CONF
        }, {
        # NixOS Metadata Regeneration
        path        = "/root/bin/generate"
        permissions = "0700"
        content     = <<-NIXOS_METADATA_REGEN_SCRIPT
          #!/usr/bin/env bash
          IFS=$'\n'
          rootfsdev="$(df "/" --output=source | sed 1d)"
          rootfstype="$(df $rootfsdev --output=fstype | sed 1d)"
          esp=$(df "/boot/efi" --output=source | sed 1d)
          espfstype="$(df $esp --output=fstype | sed 1d)"
          eth0_mac=$(ifconfig eth0 | awk '/ether/{print $2}')
          eth1_mac=$(ifconfig eth1 | awk '/ether/{print $2}')
          test ! -r /etc/nixos/generated.toml || mv /etc/nixos/generated.toml /etc/nixos/generated.bkp.toml
          cat <<-__TOML_FILE_CONTENTS | tee /etc/nixos/generated.toml
          networking.hostName = "${var.node_name}"
          fileSystems."/".device = "$rootfsdev"
          fileSystems."/".fsType = "$rootfstype" 
          systemd.network.links."10-eth0".matchConfig.PermanentMACAddress = "$eth0_mac"
          systemd.network.links."10-eth0".linkConfig.Name = "eth0"
          systemd.network.links."10-eth1".matchConfig.PermanentMACAddress = "$eth1_mac"
          systemd.network.links."10-eth1".linkConfig.Name = "eth1"
          __TOML_FILE_CONTENTS
          NIXOS_METADATA_REGEN_SCRIPT
      }]

      # Final bootstrapping
      runcmd = [
        "/root/bin/generate",
        "curl ${var.infect_script} | PROVIDER=digitalocean NIXOS_IMPORT=./system.nix NIX_CHANNEL=${var.nix_channel} bash 2>&1 | tee /tmp/infect.log",
      ]
    })
  }
}

resource "digitalocean_droplet" "main" {
  count             = var.host_count
  image             = var.node_image
  name              = format("%s-%d", var.node_name, count.index)
  region            = var.region
  vpc_uuid          = data.digitalocean_vpc.default.id
  size              = var.node_size
  ipv6              = true
  monitoring        = false
  backups           = false
  droplet_agent     = false
  graceful_shutdown = false
  resize_disk       = !var.external_volumes
  user_data         = element(data.cloudinit_config.user_data.*.rendered, count.index)
  volume_ids        = var.external_volumes ? [element(digitalocean_volume.main.*.id, count.index)] : []
  ssh_keys          = data.digitalocean_ssh_keys.all.ssh_keys.*.id
  lifecycle {
    ignore_changes = [ssh_keys]
  }
}

resource "digitalocean_volume" "main" {
  count                   = var.external_volumes ? var.host_count : 0
  region                  = var.region
  name                    = format("%s-%d", var.node_name, count.index)
  description             = format("%s-%d", var.node_name, count.index)
  size                    = 100
  initial_filesystem_type = "ext4"
}

resource "digitalocean_floating_ip" "main" {
  count      = var.floating_ip ? var.host_count : 0
  droplet_id = element(digitalocean_droplet.main.*.id, count.index)
  region     = element(digitalocean_droplet.main.*.region, count.index)
}
