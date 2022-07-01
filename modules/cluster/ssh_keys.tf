variable "ssh_keys" {
  type = list(string)
  default = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDpWF/CahaYfT8299wOZhEvcGL7PCWO0HKGHdIZrOxRDdOOXbcHOylPdeuIOATj/UGRQGOwVLcVtJM8//jK7A/U2ngkQ1vm0bwy2sju61JRW4rtHrVOyIqDuNF2slbZjCG8Chwur/1NEr/oPPq1oOWgSmiz5fKE0p7uIHgloEE1sj3rJbiFXZe+u0Jaj7Hwu1OngpSULcXhb7ASiddm84ypBspiC75WXIM/85pwEHUFqcqqJ3jAqi0AMFQU3T/odmvXRi35Boua3w24SkUUAc7zZNvhtXNpD7KyTVWLyCwwtO85tiidWUybOPwofJ4/6dQ6Qi/9p2j3ZSnohdI9oEhRq+a7BQiU+T13hsIOeD18Z91k/kzg9vIgAnttD3C7ztLyGjQdN+pnPv4v2axZoqwkoygh/S/jBtT3+Ez16I7/IAl9vjeFK5RQLnm00QesadQKcYc8ZfK92MKlQ1Pl4e13H5QYHirTVcHKEXzvGp6A9RiaKRVoRowVFBsQ/EjkZeIQz3WGPH+fbZh3ON3wWzZbUo36o7plazP1Ge97A0vcqNLfmau7nDocTpYkWaFnrjDK0HPxATMrIURKDjCBAYK521x9TKQT4XO6kkGsUP87eNfpkAeHhRewNT7S+Qqc6wJhI+HEBBdZapTxxEGlcwt3dRB7izD5cKuNxq5TUp9Q2w==",
   #"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIe/jjHus5bAaW1jfHWYFKbDBgP12XXSJTxIt5dCvloI",
  ]
}

resource "digitalocean_ssh_key" "main" {
  count      = length(var.ssh_keys)
  name       = "Key ${count.index}"
  public_key = element(var.ssh_keys, count.index)
}

output "ssh_keys" {
  value = {
    count = length(var.ssh_keys)
    ids = digitalocean_ssh_key.main.*.id 
  }
}
