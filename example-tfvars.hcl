
# provision a Block Volume for each host?
external_volumes = false

# reserve a Floating IP for each host?
floating_ip = false

# how many hosts should be managed?
host_count = 1

# where is the nixos-infect script?
infect_script = "https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect"

# which nix channel should be used for managed hosts?
nix_channel = "nixos-unstable"

# which digitalocean base image should be used?
node_image = "debian-11-x64"

# what name should be given to instance(s)?
node_name = "nixlet"

# which digitalocean droplet size should be used?
node_size = "s-1vcpu-1gb-intel"

# which digitalocean region should be used?
region = "nyc3"