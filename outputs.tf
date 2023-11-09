output "ipv4_address" {
  value       = local.ipv4_address
  description = "public ipv4 address"
}

output "ipv6_address" {
  value       = digitalocean_droplet.main.ipv6_address
  description = "public ipv6 address"
}

output "floating_ip" {
  description = "(augmented) floating_ip resource"
  value = !var.floating_ip ? {} : merge(digitalocean_floating_ip.main[0], {
  })
}

output "droplet" {
  description = "(augmented) droplet resource"
  value = merge(digitalocean_droplet.main, {
    ssh_command  = format("ssh %s@%s", local.ssh_username, local.ipv4_address)
    ssh_username = "root"
  })
}
