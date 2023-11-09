variable "hostname" {
  default     = "nixlet"
  type        = string
  description = "what name should be given to instance?"
}

variable "vpc_name" {
  default     = "default"
  type        = string
  description = "name of the VPC to target, if \"default\" will be appended with -$region"
}

variable "ssh_key_ids" {
  default     = []
  type        = list(number)
  description = "ssh key ids to grant root ssh access. does not create them. if unspecified, all currently available ssh keys will be used (within the  project containing this API token)."
}

variable "volume_ids" {
  default     = []
  type        = list(number)
  description = "list of volumes to be mounted to the created droplet."
}

variable "region" {
  default     = "nyc3"
  type        = string
  description = "which digitalocean region should be used?"
}

variable "droplet_size" {
  default     = "s-1vcpu-1gb-intel"
  description = "which digitalocean droplet size should be used?"
  type        = string
}

variable "floating_ip" {
  default     = true
  type        = bool
  description = "reserve a floating IP droplet host?"
}

variable "ipv6" {
  default     = true
  type        = bool
  description = "enable ipv6?"
}

variable "nixos_config" {
  default     = ""
  type        = string
  description = "file contents of custom.nix (if empty, default will be used)"
}

variable "flake_config" {
  default     = ""
  type        = string
  description = "file contents of flake.nix (if empty, default will be generated)"
}

variable "infect_script" {
  default     = ""
  type        = string
  description = "file contents of infect.sh (if empty, default will be used)"
}

variable "nixos_system" {
  default = "x86_64-linux"
  type    = string
}

variable "nixos_channel" {
  default     = "nixos-unstable"
  type        = string
  description = "which nix channel should be used for managed hosts?"
}

variable "graceful_shutdown" {
  default     = false
  type        = bool
  description = "allow this droplet to shutdown gracefully?"
}

variable "backups" {
  default     = false
  type        = bool
  description = "enable regular digitalocean droplet backups"
}

variable "resize_disk" {
  default     = false
  type        = bool
  description = "resize disk when resizing the droplet (permanent change)"
}

variable "image" {
  default     = "debian-11-x64"
  description = "change this at your own risk. it \"just works\" like this..."
  type        = string
}

variable "droplet_tags" {
  default     = []
  description = "tags to apply to droplet."
  type        = list(string)
}
