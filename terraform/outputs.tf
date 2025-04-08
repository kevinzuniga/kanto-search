output "ecr_repository_url" {
  value = aws_ecr_repository.kanto_repo.repository_url
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.valkey.primary_endpoint_address
}

output "ecs_service_name" {
  value = aws_ecs_service.kanto_service.name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.kanto_cluster.name
}