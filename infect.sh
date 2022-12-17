#!/usr/bin/env bash
set -euo pipefail && IFS=$'\n'

# helper functions.
fatal(){  error "$@" && exit 1; }
error(){  echo -e "\n[ERROR]:    $@\n" >&2; }
warn(){   echo -e "\n[WARNING]:  $@\n" >&2; }
info(){   echo -e "\n[INFO]:     $@\n" >&2; }
require_bin(){  type -p "$1" >/dev/null 2>&1 || (fatal "missing $1"); }
require_bins(){ for a in "$@"; do require_bin "$a"; done; }
require_root(){ [[ $EUID -eq 0 ]] || fatal "must be run as root user (try sudo)"; }

# perform final "pre-flight checks"...
require_root && require_bins curl jq df

# cache the metadata file for use below.
metadata="$(mktemp)" && readonly metadata
curl http://169.254.169.254/metadata/v1.json >"$metadata"
query_metadata(){ jq -Se "$@" "$metadata"; }

export SYSTEM_CONFIG="${SYSTEM_CONFIG:-/etc/nixos/configuration.nix}"
# If the output file already exists, make a backup.
test ! -r "$SYSTEM_CONFIG" || mv "$SYSTEM_CONFIG" "$SYSTEM_CONFIG.old"
# We're finally ready to generate the configuration.
cat <<-__GENERATED_SYSTEM_CONFIG__ | tee "$SYSTEM_CONFIG"
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
__GENERATED_SYSTEM_CONFIG__

info 'everything except the files listed below will be purged from the system on reboot:'
cat <<-__PROTECTED_FILES__ | tee /etc/NIXOS_LUSTRATE && touch /etc/NIXOS
etc/nixos
etc/resolv.conf
var/log/cloud-init-output.log
root/.nix-defexpr/channels
$(cd / && ls etc/ssh/ssh_host_*_key* || true)
__PROTECTED_FILES__


info 'install nix if its not already installed.' && test -r ~/.nix-profile/etc/profile.d/nix.sh || curl -L 'https://nixos.org/nix/install' | sh
info 'load our nix profile into the current environment.' && source ~/.nix-profile/etc/profile.d/nix.sh

info 'use specified nix-channel' && nix-channel --remove nixpkgs && nix-channel --add "https://nixos.org/channels/${NIX_CHANNEL:-nixos-unstable}" nixos
nix-channel --update && info 'update our nix-channel cache.'

info 'build our (future) nixos "system" profile from the "default" nix profile for the root user.'
if test -r '/etc/nixos/flake.nix'; then
    nix build --no-link --profile '/nix/var/nix/profiles/system' \
        "/etc/nixos#nixosConfigurations.$(hostname -s).config.system.build.toplevel"
else
    nix-env --set -f '<nixpkgs/nixos>' -A system \
        -I nixos-config='/etc/nixos/configuration.nix' \
        -I nixpkgs="$HOME/.nix-defexpr/channels/nixos" \
        -p '/nix/var/nix/profiles/system'
fi

# Stage the Nix coup d'état
# Unless otherwise specified, its time to start preparing/activating the NixOS "system" profile.
if [[ -z "${NO_ACTIVATE:-}" ]]; then
    info 'Cleanup "default" nix installation for the root user.'
    rm -fv /nix/var/nix/profiles/default* && /nix/var/nix/profiles/system/sw/bin/nix-collect-garbage

    info 'reify resolv.conf'
    [[ -L /etc/resolv.conf ]] && mv -v /etc/resolv.conf /etc/resolv.conf.lnk && cat /etc/resolv.conf.lnk > /etc/resolv.conf

    info 'create a safe copy of the boot directory' && if test -d /boot; then
      # We make a copy of the boot directory, if it exists, in case we hope to recover later.
      # Honestly, this might not be that useful...
      mv -v /boot /boot.bak || { cp -a /boot /book.bak ; rm -rf /boot/* ; umount /boot ; }
    fi

    info 'switch to our configuration on next boot.' && /nix/var/nix/profiles/system/bin/switch-to-configuration boot
    info 'unless otherwise specified its time to reboot and cross our fingers!' && if [[ -z "${NO_REBOOT:-}" ]]; then reboot; fi
fi
