# nixlet.tf

a [terraform] module to create a [nixos] droplet on [digitalocean].

## usage

1. install [terraform]

2. run `terraform init` to fetch required providers.

3. export `DIGITALOCEAN_TOKEN=...` to set your credentials.

4. plan a deployment with `terraform plan`.

5. apply the plan with `terraform apply`.

[terraform]: https://terraform.io
[digitalocean]: https://digitalocean.com
[nixos]: https://nixos.org
