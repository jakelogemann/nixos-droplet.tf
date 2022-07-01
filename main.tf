module "cluster" {
  source = "./modules/cluster"
}

output "cluster" {
  description = "outputs from the cluster module."
  value       = module.cluster
}
