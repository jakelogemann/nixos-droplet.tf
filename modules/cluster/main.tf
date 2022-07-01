variable "cluster_name" {
  default = "infra"
}

variable "region" {
  default = "nyc3"
}

variable "domain" {
  default = "fnctl.io"
}

variable "cluster_ip_range" {
  default = "10.10.10.0/24"
}

resource "digitalocean_vpc" "main" {
  name        = var.cluster_name
  region      = var.region
  description = "main ${var.cluster_name} vpc"
  ip_range    = var.cluster_ip_range
}

variable "node_image" {
  default = "debian-11-x64"
}

variable "node_size" {
  default = "g-2vcpu-8gb"
}

variable "node_count" {
  default = 1
}

resource "digitalocean_tag" "nodes" {
  name = var.cluster_name
}

resource "digitalocean_droplet" "nodes" {
  count             = var.node_count
  image             = var.node_image
  name              = "${var.cluster_name}-node${count.index}"
  region            = var.region
  vpc_uuid          = digitalocean_vpc.main.id
  size              = var.node_size
  ipv6              = true
  tags              = [digitalocean_tag.nodes.id]
  monitoring        = false
  backups           = false
  droplet_agent     = false
  graceful_shutdown = true
  user_data         = data.cloudinit_config.nodes[count.index].rendered
  ssh_keys          = digitalocean_ssh_key.main.*.id
}

data "cloudinit_config" "nodes" {
  count         = var.node_count
  gzip          = false
  base64_encode = false

  # Create nix build group and users
  part {
    content_type = "text/cloud-config"
    filename = "users.yml"
    content = yamlencode({
      groups = [ "nixbld" ]
      users = [
        for id in range(0,9): {
            name          = "nixbld${id}"
            no_user_group = true
            system        = true
            gecos         = "Nix build user ${id}"
            primary_group = "nixbld"
        }
      ]
    })
  }

  # Create Nix files 
  part {
    content_type = "text/cloud-config"
    filename     = "nix_files.yml"
    content = yamlencode({
      write_files = [
        {
          path        = "/etc/NIXOS_LUSTRATE"
          append      = true
          content     = join("\n", ["etc/nixos", "etc/resolv.conf", "root/.nix-defexpr/channels"])
        },
        {
          path = "/etc/NIXOS"
        },
        {
          path = "/etc/nixos/configuration.nix"
        },
      ]
    })
  }

  part {
    content_type = "text/cloud-config"
    filename     = "phase0.yml"
    content = yamlencode({
      write_files = [
        {
          path        = "/etc/nixos/shim.nix"
          permissions = "0644"
          content     = <<-CONFIG
      {config, lib, options, pkgs, ...}: {
        environment.systemPackages = with pkgs; [ vim ];
        users.users.root.initialPassword = "";
        networking.hostName = "nixlet";
        users.users.root.openssh.authorizedKeys.keys = [ "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBABySeaOu0G1iaMa5HLZVUrtd4WDqqzE+0Wt9QTsHqf/oAAeOLzY8he5/IR/Fymjsf3dUvC9k1Ye4BhBWLwt18JDZAAFdNA8zHmQWXoxSNKqhfj1elZkdr1s4iHQYCtIi5DqVY/l+m8GIVU/XbWUojQroimTZAcbHQ54WdjPW2YPSxyEEQ== draven" ];
        networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
      }
    CONFIG
        },
      ]
    })
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "infect.sh"
    content      = file("${path.module}/infect.sh")
  }
}

output "vpc" {
  value = digitalocean_vpc.main
}

output "nodes" {
  value = digitalocean_droplet.nodes
}
