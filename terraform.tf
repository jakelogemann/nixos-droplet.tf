variable "cloudflare_zone_id" {
  default = "55ed2ea4c2ce58b835c5319f1f2e6dc0"
}

variable "cloudflare_account_id" {
  default = "b9df8b7a4c8eb89d4627eac1426a4d95"
}

variable "cloudflare_email" {
  default = "jake@lgmn.io"
}

terraform {
  # backend "s3" {
  #   bucket  = "nixos-terraform-state"
  #   encrypt = true
  #   key     = "targets/terraform"
  #   region  = "eu-west-1"
  # }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}
