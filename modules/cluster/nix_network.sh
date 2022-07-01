#! /usr/bin/env bash
set -e -o pipefail

# XXX It'd be better if we used procfs for all this...
local IFS=$'\n'
eth0_name=$(ip address show | grep '^2:' | awk -F': ' '{print $2}')
eth0_ip4s=$(ip address show dev "$eth0_name" | grep 'inet ' | sed -r 's|.*inet ([0-9.]+)/([0-9]+).*|{ address="\1"; prefixLength=\2; }|')
eth0_ip6s=$(ip address show dev "$eth0_name" | grep 'inet6 ' | sed -r 's|.*inet6 ([0-9a-f:]+)/([0-9]+).*|{ address="\1"; prefixLength=\2; }|' || '')
gateway=$(ip route show dev "$eth0_name" | grep default | sed -r 's|default via ([0-9.]+).*|\1|')
gateway6=$(ip -6 route show dev "$eth0_name" | grep default | sed -r 's|default via ([0-9a-f:]+).*|\1|' || true)
ether0=$(ip address show dev "$eth0_name" | grep link/ether | sed -r 's|.*link/ether ([0-9a-f:]+) .*|\1|')

eth1_name=$(ip address show | grep '^3:' | awk -F': ' '{print $2}')||true
if [ -n "$eth1_name" ];then
  eth1_ip4s=$(ip address show dev "$eth1_name" | grep 'inet ' | sed -r 's|.*inet ([0-9.]+)/([0-9]+).*|{ address="\1"; prefixLength=\2; }|')
  eth1_ip6s=$(ip address show dev "$eth1_name" | grep 'inet6 ' | sed -r 's|.*inet6 ([0-9a-f:]+)/([0-9]+).*|{ address="\1"; prefixLength=\2; }|' || '')
  ether1=$(ip address show dev "$eth1_name" | grep link/ether | sed -r 's|.*link/ether ([0-9a-f:]+) .*|\1|')
  interfaces1=<< EOF
    $eth1_name = {
      ipv4.addresses = [$(for a in "${eth1_ip4s[@]}"; do echo -n "
        $a"; done)
      ];
      ipv6.addresses = [$(for a in "${eth1_ip6s[@]}"; do echo -n "
        $a"; done)
      ];
EOF
  extraRules1="ATTR{address}==\"${ether1}\", NAME=\"${eth1_name}\""
else
  interfaces1=""
  extraRules1=""
fi

readarray nameservers < <(grep ^nameserver /etc/resolv.conf | sed -r \
  -e 's/^nameserver[[:space:]]+([0-9.a-fA-F:]+).*/"\1"/' \
  -e 's/127[0-9.]+/8.8.8.8/' \
  -e 's/::1/8.8.8.8/' )

if [[ "$eth0_name" = eth* ]]; then
  predictable_inames="usePredictableInterfaceNames = lib.mkForce false;"
else
  predictable_inames="usePredictableInterfaceNames = lib.mkForce true;"
fi
cat > /etc/nixos/networking.nix << EOF
{ lib, ... }: {
# This file was populated at runtime with the networking
# details gathered from the active system.
networking = {
  nameservers = [ ${nameservers[@]} ];
  defaultGateway = "${gateway}";
  defaultGateway6 = "${gateway6}";
  dhcpcd.enable = false;
  $predictable_inames
  interfaces = {
    $eth0_name = {
      ipv4.addresses = [$(for a in "${eth0_ip4s[@]}"; do echo -n "
        $a"; done)
      ];
      ipv6.addresses = [$(for a in "${eth0_ip6s[@]}"; do echo -n "
        $a"; done)
      ];
      ipv4.routes = [ { address = "${gateway}"; prefixLength = 32; } ];
      ipv6.routes = [ { address = "${gateway6}"; prefixLength = 128; } ];
    };
    $interfaces1
  };
};
services.udev.extraRules = ''
  ATTR{address}=="${ether0}", NAME="${eth0_name}"
  $extraRules1
'';
}
EOF