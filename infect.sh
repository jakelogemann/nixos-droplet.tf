#!/usr/bin/env bash
set -euo pipefail && IFS=$'\n'
export NIXOS_CONFIG="${NIXOS_CONFIG:-/etc/nixos/configuration.nix}"

# If the output file already exists, make a backup.
test ! -r "$NIXOS_CONFIG" || mv "$NIXOS_CONFIG" "$NIXOS_CONFIG.old"

# cache the metadata file for use below.
metadata="$(mktemp)" && readonly metadata
curl http://169.254.169.254/metadata/v1.json >"$metadata"
query_metadata(){ jq -Se "$@" "$metadata"; }

# We're finally ready to generate the configuration.
cat <<-__GENERATED_NIXOS_CONFIG__ | tee "$NIXOS_CONFIG"
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ${NIXOS_IMPORT:-}
  ];

  boot.cleanTmpDir = true;
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
  boot.initrd.kernelModules = ["nvme"];
  boot.loader.grub.device = "$(for d in /dev/vda /dev/sda /dev/xvda /dev/nvme0n1 ; do [[ -e $d ]] && echo $d && break; done)";
  zramSwap.enable = true;

  fileSystems."/" = {
    device = "$(df / --output=source | sed 1d)";
    fsType = "$(df / --output=fstype | sed 1d)";
  };

  networking = {
    domain = "$(hostname -d)";
    hostName = "$(hostname -s)";
    # DNS servers are provided by the metadata.
    nameservers = [$(query_metadata '.dns.nameservers[]' | tr '\n' ' ')];
    # DigitalOcean uses legacy interface names...
    usePredictableInterfaceNames = lib.mkForce false;
    # DHCP seems to be problematic too..
    dhcpcd.enable = lib.mkForce false;
    interfaces.eth0.useDHCP = lib.mkForce false;
    interfaces.eth1.useDHCP = lib.mkForce false;
    # Statically configure IPv4 from supplied metadata.
    # TODO: this is very fragile, im too lazy to parse the prefix length..
    defaultGateway = $(query_metadata '.interfaces.public[0].ipv4.gateway');
    defaultGateway6 = $(query_metadata '.interfaces.public[0].ipv6.gateway');
    interfaces.eth0.ipv4.addresses = [
      { prefixLength = 20; address = $(query_metadata '.interfaces.public[0].ipv4.ip_address'); }
      { prefixLength = 16; address = $(query_metadata '.interfaces.public[0].anchor_ipv4.ip_address'); }
    ];
    interfaces.eth0.ipv6.addresses = [{ prefixLength = 64; address = $(query_metadata '.interfaces.public[0].ipv6.ip_address'); }];
    interfaces.eth0.ipv4.routes = [{ prefixLength =  32; address = $(query_metadata '.interfaces.public[0].ipv4.gateway'); }];
    interfaces.eth0.ipv6.routes = [{ prefixLength = 128; address = $(query_metadata '.interfaces.public[0].ipv6.gateway'); }];
  };
  # SSH should be setup and use reasonably sane defaults.
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [$(query_metadata '.public_keys[]' | tr '\n' ' ')];
  # Ensures that DigitalOcean interface names are not lost in the switch to Nix.
  services.udev.extraRules = ''
    ATTR{address}==$(query_metadata '.interfaces.public[0].mac'), NAME="eth0"
    ATTR{address}==$(query_metadata '.interfaces.private[0].mac'), NAME="eth1"
  '';
}
__GENERATED_NIXOS_CONFIG__

# Install Nix if its not already installed.
test -r ~/.nix-profile/etc/profile.d/nix.sh || curl -L https://nixos.org/nix/install | sh
source ~/.nix-profile/etc/profile.d/nix.sh

# Set the Nix channel and update it.
nix-channel --remove nixpkgs
nix-channel --add "https://nixos.org/channels/${NIX_CHANNEL:-nixos-unstable}" nixos
nix-channel --update

# Build our (future) NixOS system.
nix-env --set \
  -I nixpkgs=$HOME/.nix-defexpr/channels/nixos \
  -f '<nixpkgs/nixos>' \
  -p /nix/var/nix/profiles/system \
  -A system

# Remove nix installed with curl | bash
rm -fv /nix/var/nix/profiles/default*
/nix/var/nix/profiles/system/sw/bin/nix-collect-garbage

# Reify resolv.conf
[[ -L /etc/resolv.conf ]] && mv -v /etc/resolv.conf /etc/resolv.conf.lnk && cat /etc/resolv.conf.lnk > /etc/resolv.conf

# Stage the Nix coup d'état
touch /etc/NIXOS
cat <<-__PROTECTED_FILES__ >/etc/NIXOS_LUSTRATE
etc/nixos
etc/resolv.conf
root/.nix-defexpr/channels
$(cd / && ls etc/ssh/ssh_host_*_key* || true)
__PROTECTED_FILES__

if test -d /boot; then
  mv -v /boot /boot.bak || { cp -a /boot /book.bak ; rm -rf /boot/* ; umount /boot ; }
fi

readonly activation_script=/nix/var/nix/profiles/system/bin/switch-to-configuration
test ! -x "$activation_script" || $activation_script boot

if [[ -z "${NO_REBOOT:-}" ]]; then
  reboot
fi
