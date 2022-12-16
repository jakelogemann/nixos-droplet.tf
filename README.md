# [NixOS] + droplet = _"nixlet"_ 🦗

[terraform-docs]: https://terraform-docs.io
[terraform]: https://terraform.io
[digitalocean]: https://digitalocean.com
[nixos]: https://nixos.org
[nix]: https://nixos.org
[`DIGITALOCEAN_TOKEN`]: https://cloud.digitalocean.com/account/api/tokens/new
[droplet monitoring]: https://docs.digitalocean.com/products/monitoring/details/features/#what-can-the-metrics-agent-access

a [terraform] module to create a [nixos] droplet on [digitalocean]. **_heavily inspired_** by [elitak/nixos-infect](https://github.com/elitak/nixos-infect) but tuned explicitly for our tools, processes, and preferences. the goal is a quick to setup (ephemeral or long-lasting!) [nixos] host on [digitalocean] without too much headache and to provide an easy way for new developers to begin experimenting with this operating-system/platform.

## 🌟 features

- 🏖️ no [nix] installation necessary! 😌 _only [terraform] and a [`DIGITALOCEAN_TOKEN`]_!
- ⏲️ deployed and ready in _**"under 5-microwave minutes"**_ 🍗.
- 👷‍♂️ **custom configuration** _is easy!_ 🍬 _(but also **not required**)_ 💆
- 📡 advanced **[droplet monitoring]** enabled! 👽 🛸

## 📋 use cases

- 🦺 demonstrations.
- 🎓 a safe and productive learning environment for beginners to explore.
- 📝 developer's scratchpad.
- 🔬 "clean room" for further analysis.
- 🦠 other miscellaneous experimentation.
  - [tailscale node(s)](https://nixos.org/manual/nixos/stable/options.html#opt-services.tailscale.enable).
  - [dnscrypt-proxy2](https://nixos.org/manual/nixos/stable/options.html#opt-services.dnscrypt-proxy2.enable) encrypted DNS server.
  - [caddy](https://nixos.org/manual/nixos/stable/options.html#opt-services.caddy.enable) web server.
  - [mastodon](https://nixos.org/manual/nixos/stable/options.html#opt-services.mastodon.enable) federated social network server.
  - [logging/tracing/event processing](https://nixos.org/manual/nixos/stable/options.html#opt-services.vector.enable).
  - [self-hosted code-server](https://nixos.org/manual/nixos/stable/options.html#opt-services.code-server.enable).
  - [grafana](https://nixos.org/manual/nixos/stable/options.html#opt-services.grafana.enable), [prometheus](https://nixos.org/manual/nixos/stable/options.html#opt-services.prometheus.enable), [victoriametrics](https://nixos.org/manual/nixos/stable/options.html#opt-services.victoriametrics.enable).
  - [factorio server](https://nixos.org/manual/nixos/stable/options.html#opt-services.factorio.enable)
  - [minio s3 filestore](https://nixos.org/manual/nixos/stable/options.html#opt-services.minio.enable)
  - [jupyterhub](https://nixos.org/manual/nixos/stable/options.html#opt-services.jupyterhub.enable) with support for **_any_** kernel you want badly enough.
  - _so many more..._ (**TODO**: clean up this rambling fever dream of possible uses)

## 🚀 module

**Configuration can live next to `.tf` files, by using `file()`**:

```hcl
module "nixlet" {
  # note that every other value (besides source) is NOT required.
  source        = "github.com/polis-dev/nixlet.tf"

  # increased droplet size to make nixlet go vroooom!
  droplet_size  = "s-4vcpu-8gb-intel"

  # defaults to nixos-unstable, with flakes, and other sane defaults.
  nixos_channel = "nixos-unstable"

  # custom nixos configuration can be specified via file() like so.
  nixos_config  = file("${path.module}/custom.nix")
}
```

**OR configurations can embed/inline the nix file to leverage [terraform]'s string interpolation**:

```hcl
locals { domain = "example.com" }
module "nixlet" {
  # note that every other value (besides source) is NOT required.
  source        = "github.com/polis-dev/nixlet.tf"
  nixos_config  = <<-NIXOS_CONFIG
  { config, lib, pkgs, ... }: {
    networking.domain = "${domain}";
    /*
    add your configuration here...
    */
  }
  NIXOS_CONFIG
}
```

Then run `terraform init` and then `terraform plan`.


<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) (~> 2.2)

- <a name="requirement_digitalocean"></a> [digitalocean](#requirement\_digitalocean) (~> 2.0)

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_backups"></a> [backups](#input\_backups)

Description: enable regular digitalocean droplet backups

Type: `bool`

Default: `false`

### <a name="input_droplet_size"></a> [droplet\_size](#input\_droplet\_size)

Description: which digitalocean droplet size should be used?

Type: `string`

Default: `"s-1vcpu-1gb-intel"`

### <a name="input_droplet_tags"></a> [droplet\_tags](#input\_droplet\_tags)

Description: tags to apply to droplet.

Type: `list(string)`

Default: `[]`

### <a name="input_flake_config"></a> [flake\_config](#input\_flake\_config)

Description: file contents of flake.nix (if empty, default will be generated)

Type: `string`

Default: `""`

### <a name="input_floating_ip"></a> [floating\_ip](#input\_floating\_ip)

Description: reserve a floating IP droplet host?

Type: `bool`

Default: `true`

### <a name="input_graceful_shutdown"></a> [graceful\_shutdown](#input\_graceful\_shutdown)

Description: allow this droplet to shutdown gracefully?

Type: `bool`

Default: `false`

### <a name="input_hostname"></a> [hostname](#input\_hostname)

Description: what name should be given to instance?

Type: `string`

Default: `"nixlet"`

### <a name="input_image"></a> [image](#input\_image)

Description: change this at your own risk. it "just works" like this...

Type: `string`

Default: `"debian-11-x64"`

### <a name="input_infect_script"></a> [infect\_script](#input\_infect\_script)

Description: file contents of infect.sh (if empty, default will be used)

Type: `string`

Default: `""`

### <a name="input_ipv6"></a> [ipv6](#input\_ipv6)

Description: enable ipv6?

Type: `bool`

Default: `true`

### <a name="input_nixos_channel"></a> [nixos\_channel](#input\_nixos\_channel)

Description: which nix channel should be used for managed hosts?

Type: `string`

Default: `"nixos-unstable"`

### <a name="input_nixos_config"></a> [nixos\_config](#input\_nixos\_config)

Description: file contents of custom.nix (if empty, default will be used)

Type: `string`

Default: `""`

### <a name="input_nixos_system"></a> [nixos\_system](#input\_nixos\_system)

Description: n/a

Type: `string`

Default: `"x86_64-linux"`

### <a name="input_region"></a> [region](#input\_region)

Description: which digitalocean region should be used?

Type: `string`

Default: `"nyc3"`

### <a name="input_resize_disk"></a> [resize\_disk](#input\_resize\_disk)

Description: resize disk when resizing the droplet (permanent change)

Type: `bool`

Default: `false`

### <a name="input_ssh_key_ids"></a> [ssh\_key\_ids](#input\_ssh\_key\_ids)

Description: ssh key ids to grant root ssh access. does not create them. if unspecified, all currently available ssh keys will be used (within the  project containing this API token).

Type: `list(number)`

Default: `[]`

### <a name="input_volume_ids"></a> [volume\_ids](#input\_volume\_ids)

Description: list of volumes to be mounted to the created droplet.

Type: `list(number)`

Default: `[]`

### <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name)

Description: name of the VPC to target, if "default" will be appended with -$region

Type: `string`

Default: `"default"`

## Outputs

The following outputs are exported:

### <a name="output_droplet"></a> [droplet](#output\_droplet)

Description: (augmented) droplet resource

### <a name="output_floating_ip"></a> [floating\_ip](#output\_floating\_ip)

Description: (augmented) floating\_ip resource

### <a name="output_ipv4_address"></a> [ipv4\_address](#output\_ipv4\_address)

Description: public ipv4 address

### <a name="output_ipv6_address"></a> [ipv6\_address](#output\_ipv6\_address)

Description: public ipv6 address
<!-- END_TF_DOCS -->


## stand-alone / local setup

1. install [terraform] and [terraform-docs].

2. clone the repository and run `./terraform.sh init` to setup providers. you can run `./terraform.sh` to see available commands.

3. export `DIGITALOCEAN_TOKEN=...` (directly, or via the newly created `.envrc`) to set your access credentials.

4. plan a deployment with `./terraform.sh plan`.

5. apply the plan with `./terraform.sh apply`. allow ~5 minutes (with default config) to provision completely (or just `tail -f /var/log/cloud-init-output.log`).

6. ssh to your host and enjoy! clean up everything with `./terraform.sh destroy`.

## troubleshooting

**_"i logged into my host and its not nixos! its debian!"_**:

well, "_future self at 3am_", you can read through the log output from cloud-init with `less /var/log/cloud-init-output.log`. often a small syntax error or a minor typo can cause the initial build to fail. you will almost certainly want to start the provisioning process over entirely after making your correction locally; luckily with [terraform] thats pretty easy: `./terraform.sh apply -destroy`, then `./terraform.sh apply` to create it again.

_NOTE that the documentation is automatically updated by [terraform-docs]._
