resource "digitalocean_spaces_bucket" "cache" {
  count = 0
  name   = "${var.cluster_name}-cache"
  region = var.region

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "DELETE"]
    allowed_origins = ["https://cache.${var.domain}"]
    max_age_seconds = 3000
  }
}

resource "digitalocean_spaces_bucket_policy" "cache" {
  region = digitalocean_spaces_bucket.cache.region
  bucket = digitalocean_spaces_bucket.cache.name
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "IPAllow",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${digitalocean_spaces_bucket.cache.name}",
                "arn:aws:s3:::${digitalocean_spaces_bucket.cache.name}/*"
            ],
            "Condition": {
                "NotIpAddress": {
                    "aws:SourceIp": digitalocean_vpc.main.ip_range
                }
            }
        }
    ]
  })
}

resource "cloudflare_record" "cache" {
  zone_id = var.cloudflare_zone_id
  name    = "cache"
  value   = digitalocean_spaces_bucket.cache.bucket_domain_name
  type    = "CNAME"
  allow_overwrite = true
}
