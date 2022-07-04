variable "nixos_version" {
  default = "22.05"
}

variable "zramswap" {
  default     = false
  description = "On  machines  with low memory, mitigates the tedious situation where the machine is out of memory and then it starts swapping to disk only to lose a large amount of disk bandwidth."
}

variable "extra_nixos_config" {
  default = ""
}

data "cloudinit_config" "user_data" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "bootstrap.yml"
    content_type = "text/cloud-config"
    content = yamlencode({
      groups = ["nixbld"]
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
      write_files = [{
        path = "/etc/NIXOS_LUSTRATE"
        content = "${join("\n", [
          "etc/nixos",
          "etc/resolv.conf",
          "root/.nix-defexpr/channels",
        ])}\n"
        }, {
        path        = "/etc/nix/nix.conf"
        permissions = "0644"
        content     = <<-NIX_CONF
          experimental-features = nix-command flakes ca-derivations
          build-users-group = nixbld
          auto-optimise-store = true
          download-attempts = 3
          enforce-determinism = true
          eval-cache = true
          http-connections = 50
          log-lines = 30
          warn-dirty = false
          allowed-users = root
          trusted-users = root
        NIX_CONF
        }, {
        path        = "/etc/nixos/generated.toml"
        permissions = "0644"
        content     = <<-NIXOS_DATA
          networking.hostName = "${var.node_name}"
        NIXOS_DATA
        }, {
        path        = "/etc/nixos/configuration.nix"
        permissions = "0644"
        content     = file("configuration.nix")
      }]
      runcmd = [
        "test -d /root/.config/nix || mkdir -vp /root/.config/nix",
        "touch /etc/NIXOS && ln -vfs /etc/nix/nix.conf /root/.config/nix/nix.conf",
        "curl -L https://nixos.org/nix/install | env HOME=/root sh",
        ". /root/.nix-profile/etc/profile.d/nix.sh",
        "nix-channel --remove nixpkgs && nix-channel --add 'https://nixos.org/channels/nixos-${var.nixos_version}' nixos && nix-channel --update",
        "export NIXOS_CONFIG=/etc/nixos/configuration.nix",
        join("  ", [
          "nix-env --set",
          "-I nixpkgs=/root/.nix-defexpr/channels/nixos",
          "-f '<nixpkgs/nixos>'",
          "-p /nix/var/nix/profiles/system",
          "-A system",
        ]),
        ## Remove nix installed with curl | bash
        # "rm -fv /nix/var/nix/profiles/default* && /nix/var/nix/profiles/system/sw/bin/nix-collect-garbage",
        # Reify resolv.conf
        "[[ -L /etc/resolv.conf ]] && mv -v /etc/resolv.conf /etc/resolv.conf.lnk && cat /etc/resolv.conf.lnk > /etc/resolv.conf",
      ]
    })

  }

  # part {
  #   content_type = "text/x-shellscript"
  #   filename     = "infect.sh"
  #   content      = file("${path.module}/infect.sh")
  # }
}

