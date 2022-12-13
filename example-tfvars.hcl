
# which digitalocean droplet size should be used?
droplet_size = "s-1vcpu-1gb-intel"

# tags to apply to droplet.
droplet_tags = [
  "nixos"
]

# provision a Block Volume for host?
extra_volume = false

# how big should the extra volume be in GB?
extra_volume_size = 100

# reserve a floating IP droplet host?
floating_ip = true

# what name should be given to instance?
hostname = "nixlet"

# change this at your own risk. it "just works" like this...
image = "debian-11-x64"

# which nix channel should be used for managed hosts?
nixos_channel = "nixos-unstable"

# extra nixos config file, included in place of the default custom.nix in this module.
nixos_config = ""

# which digitalocean region should be used?
region = "nyc3"

# ssh key ids to grant root ssh access. does not create them. if unspecified, all currently available ssh keys will be used (within the  project containing this API token).
ssh_key_ids = []

# name of the VPC to target, if "default" will be appended with -$region
vpc_name = "default"