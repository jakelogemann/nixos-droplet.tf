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

- quick, ephemeral [nixos] hosts.
  - beginners need to be safe in their sandbox to explore.
  - developers need a scratchpad for experimentation.
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

## 🚀 use it as a [terraform] module

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

## Inputs

The following input variables are supported:

### <a name="input_droplet_size"></a> [droplet\_size](#input\_droplet\_size)

Description: which digitalocean droplet size should be used?

Default: `"s-1vcpu-1gb-intel"`

### <a name="input_droplet_tags"></a> [droplet\_tags](#input\_droplet\_tags)

Description: tags to apply to droplet.

Default:

```json
[
  "nixos"
]
```

### <a name="input_extra_volume"></a> [extra\_volume](#input\_extra\_volume)

Description: provision a Block Volume for host?

Default: `false`

### <a name="input_extra_volume_size"></a> [extra\_volume\_size](#input\_extra\_volume\_size)

Description: how big should the extra volume be in GB?

Default: `100`

### <a name="input_floating_ip"></a> [floating\_ip](#input\_floating\_ip)

Description: reserve a floating IP droplet host?

Default: `true`

### <a name="input_hostname"></a> [hostname](#input\_hostname)

Description: what name should be given to instance?

Default: `"nixlet"`

### <a name="input_image"></a> [image](#input\_image)

Description: change this at your own risk. it "just works" like this...

Default: `"debian-11-x64"`

### <a name="input_nixos_channel"></a> [nixos\_channel](#input\_nixos\_channel)

Description: which nix channel should be used for managed hosts?

Default: `"nixos-unstable"`

### <a name="input_nixos_config"></a> [nixos\_config](#input\_nixos\_config)

Description: extra nixos config file, included in place of the default custom.nix in this module.

Default: `""`

### <a name="input_region"></a> [region](#input\_region)

Description: which digitalocean region should be used?

Default: `"nyc3"`

### <a name="input_ssh_key_ids"></a> [ssh\_key\_ids](#input\_ssh\_key\_ids)

Description: ssh key ids to grant root ssh access. does not create them. if unspecified, all currently available ssh keys will be used (within the  project containing this API token).

Default: `[]`

### <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name)

Description: name of the VPC to target, if "default" will be appended with -$region

Default: `"default"`

## Outputs

The following outputs are exported:

### <a name="output_ipv4_address"></a> [ipv4\_address](#output\_ipv4\_address)

Description: public ipv4 address

### <a name="output_ipv6_address"></a> [ipv6\_address](#output\_ipv6\_address)

Description: public ipv6 address

### <a name="output_remote_log_file"></a> [remote\_log\_file](#output\_remote\_log\_file)

Description: logs from cloud-init will be in this path on the remote host. you can use something like `ssh root@<IP> tail -f <PATH>` to follow installation as it goes.

### <a name="output_ssh_command"></a> [ssh\_command](#output\_ssh\_command)

Description: ssh command

### <a name="output_ssh_username"></a> [ssh\_username](#output\_ssh\_username)

Description: ssh username
<!-- END_TF_DOCS -->


## stand-alone / local setup

1. install [terraform] and [terraform-docs]. 

2. clone the repository and run `./terraform.sh init` to setup providers. you can run `./terraform.sh` to see available commands.

3. export `DIGITALOCEAN_TOKEN=...` (directly, or via the newly created `.envrc`) to set your access credentials.

4. plan a deployment with `./terraform.sh plan`.

5. apply the plan with `./terraform.sh apply`. allow ~5 minutes (with default config) to provision completely (or just `tail -f /var/log/cloud-init-output.log`).

6. ssh to your host and enjoy! clean up everything with `./terraform.sh destroy`.

## troubleshooting

### i logged into my host and its not nixos! its debian!

you can read through the log output from cloud-init with `less /var/log/cloud-init-output.log`. often a small syntax error or a minor typo can cause the initial build to fail. you will almost certainly want to start the provisioning process over entirely after making your correction locally; luckily with [terraform] thats pretty easy: `./terraform.sh apply -destroy`, then `./terraform.sh apply` to create it again.

_NOTE that the documentation is automatically updated by [terraform-docs]._
