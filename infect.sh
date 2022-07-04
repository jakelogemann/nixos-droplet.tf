#! /usr/bin/env bash

set -e -o pipefail

# DigitalOcean doesn't seem to set USER while running user data
export USER="root"
export HOME="/root"

makeConf() {
  # Skip everything if main config already present
  [[ -e /etc/nixos/configuration.nix ]] && return 0
  # NB <<"EOF" quotes / $ ` in heredocs, <<EOF does not
  mkdir -p /etc/nixos

  # Prevent grep for sending error code 1 (and halting execution) when no lines are selected : https://www.unix.com/man-page/posix/1P/grep
  local IFS=$'\n'
  for trypath in /root/.ssh/authorized_keys /home/$SUDO_USER/.ssh/authorized_keys $HOME/.ssh/authorized_keys; do
      [[ -r "$trypath" ]] \
      && keys=$(sed -E 's/^.*((ssh|ecdsa)-[^[:space:]]+)[[:space:]]+([^[:space:]]+)([[:space:]]*.*)$/\1 \3\4/' "$trypath") \
      && break
  done

  if isEFI; then
    bootcfg=$(cat << EOF
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
  fileSystems."/boot" = { device = "$esp"; fsType = "vfat"; };
EOF
)
  else
    bootcfg=$(cat << EOF
  boot.loader.grub.device = "$grubdev";
EOF
)
  fi

  # If you rerun this later, be sure to prune the filesSystems attr
  cat > /etc/nixos/hardware-configuration.nix << EOF
{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
$bootcfg
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "$rootfsdev"; fsType = "$rootfstype"; };
}
EOF
}

isEFI() {
  [ -d /sys/firmware/efi ]
}

findESP() {
  esp=""
  for d in /boot/EFI /boot/efi /boot; do
    [[ ! -d "$d" ]] && continue
    [[ "$d" == "$(df "$d" --output=target | sed 1d)" ]] \
      && esp="$(df "$d" --output=source | sed 1d)" \
      && break
  done
  [[ -z "$esp" ]] && { echo "ERROR: No ESP mount point found"; return 1; }
  for uuid in /dev/disk/by-uuid/*; do
    [[ $(readlink -f "$uuid") == "$esp" ]] && echo $uuid && return 0
  done
}

prepareEnv() {
  # $esp and $grubdev are used in makeConf()
  if isEFI; then
    esp="$(findESP)"
  else
    for grubdev in /dev/vda /dev/sda /dev/xvda /dev/nvme0n1 ; do [[ -e $grubdev ]] && break; done
  fi

  # Retrieve root fs block device
  #                   (get root mount)  (get partition or logical volume)
  rootfsdev=$(mount | grep "on / type" | awk '{print $1;}')
  rootfstype=$(df $rootfsdev --output=fstype | sed 1d)

  # Nix installer tries to use sudo regardless of whether we're already uid 0
  #which sudo || { sudo() { eval "$@"; }; export -f sudo; }
  # shellcheck disable=SC2174
  mkdir -p -m 0755 /nix
}

infect() {
  # Run nixos install script
  curl -L https://nixos.org/nix/install | sh

  source "${HOME}"/.nix-profile/etc/profile.d/nix.sh

  [[ -z "$NIX_CHANNEL" ]] && NIX_CHANNEL="nixos-unstable"
  nix-channel --remove nixpkgs
  nix-channel --add "https://nixos.org/channels/$NIX_CHANNEL" nixos
  nix-channel --update

  export NIXOS_CONFIG="${NIXOS_CONFIG:-/etc/nixos/configuration.nix}"

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

  rm -rf /boot.bak
  isEFI && umount "$esp"

  mv -v /boot /boot.bak || { cp -a /boot /book.bak ; rm -rf /boot/* ; umount /boot ; }
  if isEFI; then
    mkdir -p /boot
    mount "$esp" /boot
    find /boot -depth ! -path /boot -exec rm -rf {} +
  fi
  /nix/var/nix/profiles/system/bin/switch-to-configuration boot
}

prepareEnv
makeConf
./nix_network.sh
infect

if [[ -z "$NO_REBOOT" ]]; then
  reboot
fi
