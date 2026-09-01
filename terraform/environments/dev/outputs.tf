output "vpc_network_name" {
  value = module.vpc.network_name
}

output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "artifact_repository_url" {
  value = module.artifact_registry.repository_url
}

output "wif_provider_name" {
  value = module.wif.provider_name
}

output "chatwoot_sql_instance" {
  value = module.cloud_sql_chatwoot.instance_name
}

output "n8n_sql_instance" {
  value = module.cloud_sql_n8n.instance_name
}

output "redis_host" {
  value = module.memorystore.host
}
