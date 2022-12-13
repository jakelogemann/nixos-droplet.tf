# nixlet.tf

[terraform-docs]: https://terraform-docs.io
[terraform]: https://terraform.io
[digitalocean]: https://digitalocean.com
[nixos]: https://nixos.org

a [terraform] module to create a [nixos] droplet on [digitalocean].

## usage

1. install [terraform] and [terraform-docs]. run `./terraform.sh` to show available commands.

2. run `./terraform.sh init` to fetch required providers.

3. export `DIGITALOCEAN_TOKEN=...` (directly, or via the example .envrc) to set your credentials.

4. plan a deployment with `./terraform.sh plan`.

5. apply the plan with `./terraform.sh apply`.

6. ssh to your host and enjoy! allow ~5-10 minutes to provision; try not to modify anything while its still provisioning (or just `tail -f /var/log/cloud-init-output.log`).

7. clean up everything with `./terraform.sh destroy`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | ~> 2.2 |
| <a name="requirement_digitalocean"></a> [digitalocean](#requirement\_digitalocean) | ~> 2.0 |

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| <a name="input_droplet_size"></a> [droplet\_size](#input\_droplet\_size) | which digitalocean droplet size should be used? | `"s-1vcpu-1gb-intel"` |
| <a name="input_droplet_tags"></a> [droplet\_tags](#input\_droplet\_tags) | tags to apply to droplet. | ```[ "nixos" ]``` |
| <a name="input_extra_volume"></a> [extra\_volume](#input\_extra\_volume) | provision a Block Volume for host? | `false` |
| <a name="input_extra_volume_size"></a> [extra\_volume\_size](#input\_extra\_volume\_size) | how big should the extra volume be in GB? | `100` |
| <a name="input_floating_ip"></a> [floating\_ip](#input\_floating\_ip) | reserve a floating IP droplet host? | `true` |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | what name should be given to instance? | `"nixlet"` |
| <a name="input_image"></a> [image](#input\_image) | change this at your own risk. it "just works" like this... | `"debian-11-x64"` |
| <a name="input_nixos_channel"></a> [nixos\_channel](#input\_nixos\_channel) | which nix channel should be used for managed hosts? | `"nixos-unstable"` |
| <a name="input_nixos_config"></a> [nixos\_config](#input\_nixos\_config) | extra nixos config file, included in place of the default custom.nix in this module. | `""` |
| <a name="input_region"></a> [region](#input\_region) | which digitalocean region should be used? | `"nyc3"` |
| <a name="input_ssh_key_ids"></a> [ssh\_key\_ids](#input\_ssh\_key\_ids) | ssh key ids to grant root ssh access. does not create them. if unspecified, all currently available ssh keys will be used (within the  project containing this API token). | `[]` |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | name of the VPC to target, if "default" will be appended with -$region | `"default"` |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ipv4_address"></a> [ipv4\_address](#output\_ipv4\_address) | public ipv4 address |
| <a name="output_ipv6_address"></a> [ipv6\_address](#output\_ipv6\_address) | public ipv6 address |
| <a name="output_remote_log_file"></a> [remote\_log\_file](#output\_remote\_log\_file) | logs from cloud-init will be in this path on the remote host. you can use something like `ssh root@<IP> tail -f <PATH>` to follow installation as it goes. |
| <a name="output_ssh_command"></a> [ssh\_command](#output\_ssh\_command) | ssh command |
| <a name="output_ssh_username"></a> [ssh\_username](#output\_ssh\_username) | ssh username |
<!-- END_TF_DOCS -->

_NOTE that the documentation is automatically updated by [terraform-docs]._
