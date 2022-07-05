variable "nixos_version" {
  default = "22.05"
}

variable "domain" {
  default = "fnctl.io"
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

        # System-wide nixos configuration
        path        = "/etc/nixos/configuration.nix"
        permissions = "0644"
        content     = file("configuration.nix")
        }, {

        # System-wide nix configuration
        path        = "/etc/nix/nix.conf"
        permissions = "0644"
        content     = <<-NIX_CONF
          experimental-features = nix-command flakes
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

        # nixos lustrate - which files to persist across boot
        path = "/etc/NIXOS_LUSTRATE"
        content = "${join("\n", [
          "etc/nixos",
          "etc/resolv.conf",
          "root/.nix-defexpr/channels",
          "root/bin",
          "root/.ssh",
        ])}\n"

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
          cat <<-__TOML_FILE_CONTENTS | tee /etc/nixos/generated.toml
            fileSystems."/".device = "$rootfsdev"
            fileSystems."/".fsType = "$rootfstype" 
            systemd.network.links."10-eth0".matchConfig.PermanentMACAddress = "$eth0_mac"
            systemd.network.links."10-eth0".linkConfig.Name = "eth0"
            systemd.network.links."10-eth1".matchConfig.PermanentMACAddress = "$eth1_mac"
            systemd.network.links."10-eth1".linkConfig.Name = "eth1"
          __TOML_FILE_CONTENTS
          NIXOS_METADATA_REGEN_SCRIPT
        }, {
        path        = "/etc/nixos/flake.nix"
        permissions = "0644"
        content = <<-FLAKE_NIX
          {
            description = "${var.node_name}";
            inputs.nixpkgs.url = "github:nixos/nixpkgs/${var.nixos_version}";
            outputs = { self, nixpkgs, ... }@inputs: {
              nixosConfigurations."${var.node_name}" = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [ ./configuration.nix ];
              };
            };
          }
        FLAKE_NIX

        }, {
          path        = "/etc/nixos/flake.lock"
            permissions = "0644"
            content     = file("flake.lock")
        }, {

        # Bootstrap Script
        path        = "/root/bin/setup"
        permissions = "0750"
        content = <<-NIXOS_SETUP_SCRIPT
          #!/usr/bin/env bash
          export HOME=/root USER=root PATH="$HOME/.nix-profile/bin:$PATH"
          test -d $HOME/.config/nix || mkdir -vp $HOME/.config/nix
          touch /etc/NIXOS && ln -vfs /etc/nix/nix.conf $HOME/.config/nix/nix.conf

          curl -L https://nixos.org/nix/install | sh
          . $HOME/.nix-profile/etc/profile.d/nix.sh && cd /etc/nixos

          # Reify resolv.conf
          [[ -L /etc/resolv.conf ]] && mv -v /etc/resolv.conf /etc/resolv.conf.lnk && cat /etc/resolv.conf.lnk > /etc/resolv.conf
          # Remove nix installed with curl | bash
          # rm -fv /nix/var/nix/profiles/default* && /nix/var/nix/profiles/system/sw/bin/nix-collect-garbage

          # Switch to the new configuration on next boot & trigger reboot.
          nix flake update \
          && nix build --profile /nix/var/nix/profiles/system '/etc/nixos#nixosConfigurations.${var.node_name}.config.system.build.toplevel' \
          && ./result/bin/switch-to-configuration boot && reboot
        NIXOS_SETUP_SCRIPT
  }]

  # Final bootstrapping
  runcmd = ["/root/bin/generate", "/root/bin/setup"]
})
}
}

output "ssh_commands" {
  value = {
    cloudinit_v4 = try(format("ssh root@%s tail -fn500 /var/log/cloud-init-output.log", digitalocean_droplet.main.ipv4_address), "N/A")
    cloudinit_v6 = try(format("ssh root@%s tail -fn500 /var/log/cloud-init-output.log", digitalocean_droplet.main.ipv6_address), "N/A")
    ssh_v4       = try(format("ssh root@%s", digitalocean_droplet.main.ipv4_address), "N/A")
    ssh_v6       = try(format("ssh root@%s", digitalocean_droplet.main.ipv6_address), "N/A")
  }
}

