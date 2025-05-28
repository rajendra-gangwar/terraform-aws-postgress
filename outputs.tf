output "database_arn" {
  value = aws_rds_cluster.postgres_cluster.arn
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_secret.arn
}
