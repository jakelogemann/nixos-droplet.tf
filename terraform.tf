variable "hostname" {
  default     = "nixlet"
  type        = string
  description = "what name should be given to instance?"
}

variable "vpc_name" {
  default     = "default"
  type        = string
  description = "name of the VPC to target, if \"default\" will be appended with -$region"
}

variable "ssh_key_ids" {
  default     = []
  type        = list(number)
  description = "ssh key ids to grant root ssh access. does not create them. if unspecified, all currently available ssh keys will be used (within the  project containing this API token)."
}

variable "region" {
  default     = "nyc3"
  type        = string
  description = "which digitalocean region should be used?"
}

variable "droplet_size" {
  default     = "s-1vcpu-1gb-intel"
  description = "which digitalocean droplet size should be used?"
  type        = string
}

variable "floating_ip" {
  default     = true
  type        = bool
  description = "reserve a floating IP droplet host?"
}

variable "nixos_config" {
  default     = ""
  type        = string
  description = "extra nixos config file, included in place of the default custom.nix in this module."
}

variable "nixos_channel" {
  default     = "nixos-unstable"
  type        = string
  description = "which nix channel should be used for managed hosts?"
}

variable "extra_volume" {
  default     = false
  type        = bool
  description = "provision a Block Volume for host?"
}

variable "extra_volume_size" {
  default     = 100
  type        = number
  description = "how big should the extra volume be in GB?"
}

variable "image" {
  default     = "debian-11-x64"
  description = "change this at your own risk. it \"just works\" like this..."
  type        = string
}

variable "droplet_tags" {
  default     = ["nixos"]
  description = "tags to apply to droplet."
  type        = list(string)
}

data "digitalocean_ssh_keys" "all" {
  sort {
    key       = "name"
    direction = "asc"
  }
}

data "cloudinit_config" "user_data" {
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
        path        = "/root/infect.sh"
        permissions = "0600"
        content     = file("${path.module}/infect.sh")
        }, {
        path        = "/etc/nixos/custom.nix"
        permissions = "0644"
        content     = var.nixos_config == "" ? file("${path.module}/custom.nix") : var.nixos_config
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
      }]

      # Final bootstrapping
      runcmd = [
        "apt-get install -qqy jq",
        "env HOME=/root USER=root NIXOS_IMPORT=./custom.nix NIX_CHANNEL=${var.nixos_channel} bash /root/infect.sh 2>&1 | tee /tmp/infect.log",
      ]
    })
  }
}

data "digitalocean_vpc" "main" {
  name = var.vpc_name == "default" ? "default-${var.region}" : var.vpc_name
}

resource "digitalocean_droplet" "main" {
  image             = var.image
  name              = var.hostname
  region            = var.region
  vpc_uuid          = data.digitalocean_vpc.main.id
  size              = var.droplet_size
  ipv6              = true
  monitoring        = false
  backups           = false
  droplet_agent     = false
  graceful_shutdown = false
  resize_disk       = !var.extra_volume
  user_data         = data.cloudinit_config.user_data.rendered
  volume_ids        = var.extra_volume ? [digitalocean_volume.extra[1].id] : []
  ssh_keys          = length(var.ssh_key_ids) == 0 ? data.digitalocean_ssh_keys.all.ssh_keys.*.id : var.ssh_key_ids
  tags              = var.droplet_tags
  lifecycle {
    ignore_changes = [ssh_keys]
  }
}

resource "digitalocean_volume" "extra" {
  count                   = var.extra_volume ? 1 : 0
  region                  = var.region
  name                    = "extra-${var.hostname}"
  description             = format("Extra volume for %s.", var.hostname)
  size                    = var.extra_volume_size
  initial_filesystem_type = "ext4"
}


resource "digitalocean_floating_ip" "main" {
  count      = var.floating_ip ? 1 : 0
  droplet_id = digitalocean_droplet.main.id
  region     = digitalocean_droplet.main.region
}

locals {
  ssh_username = "root"
  ssh_options  = "-oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=accept-new"
  ipv4_address = var.floating_ip ? digitalocean_floating_ip.main[0].ip_address : digitalocean_droplet.main.ipv4_address
}

output "ipv4_address" {
  value       = local.ipv4_address
  description = "public ipv4 address"
}

output "ipv6_address" {
  value       = digitalocean_droplet.main.ipv6_address
  description = "public ipv6 address"
}

output "ssh_username" {
  value       = "root"
  description = "ssh username"
}

output "ssh_command" {
  value       = format("ssh %s %s@%s", local.ssh_options, local.ssh_username, local.ipv4_address)
  description = "ssh command"
}

output "remote_log_file" {
  value       = "/var/log/cloud-init-output.log"
  description = "logs from cloud-init will be in this path on the remote host. you can use something like `ssh root@<IP> tail -f <PATH>` to follow installation as it goes."
}

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
