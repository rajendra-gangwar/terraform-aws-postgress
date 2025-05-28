data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_db_subnet_group" "pg_subnet_group" {
  name       = "postgress-${var.pg_version}-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "database subnet group"
  }
}

resource "aws_db_parameter_group" "db_pg" {
  name   = "postgress-${var.pg_version}-db-pg"
  family = "aurora-postgresql${var.pg_version}"

  parameter {
    name  = "log_connections"
    value = "1"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "cluster_pg" {
  name        = "postgress-${var.pg_version}-cluster-pg"
  family      = "aurora-postgresql${var.pg_version}"
  description = "default cluster parameter group"
}

# Generate a random password
resource "random_password" "db_password" {
  length           = 20
  special          = false
  override_special = ""
}

# Create a Secrets Manager secret
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "postgress-dba-password"
  description = "Stores the RDS PostgreSQL database password"
  kms_key_id  = var.secretmanager_kms_key_id
}

# Store the generated password in the secret
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "${var.pg_username}"
    password = random_password.db_password.result
  })
}


resource "aws_rds_cluster" "postgres_cluster" {
  cluster_identifier               = "${var.environment}-${var.db_name}-pg-cluster"
  engine                           = "aurora-postgresql"
  engine_version                   = var.pg_version
  master_username                  = var.pg_username
  master_password                  = random_password.db_password.result
  allow_major_version_upgrade      = false
  backup_retention_period          = var.backup_retention_days
  preferred_backup_window          = var.backup_window
  preferred_maintenance_window     = var.maintenance_window
  availability_zones               = slice(data.aws_availability_zones.available.names, 0, 2)
  skip_final_snapshot              = true
  storage_encrypted                = true
  deletion_protection              = true
  copy_tags_to_snapshot            = true
  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.cluster_pg.name
  db_instance_parameter_group_name = aws_db_parameter_group.db_pg.name
  db_subnet_group_name             = aws_db_subnet_group.pg_subnet_group.name
  vpc_security_group_ids           = var.db_security_group_ids
  kms_key_id                       = var.rds_kms_key_id

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      availability_zones
    ]
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                   = var.db_instance_count
  identifier              = "${var.environment}-${var.db_name}-instance-${count.index}"
  cluster_identifier      = aws_rds_cluster.postgres_cluster.id
  instance_class          = var.pg_instance
  engine                  = aws_rds_cluster.postgres_cluster.engine
  engine_version          = aws_rds_cluster.postgres_cluster.engine_version
  copy_tags_to_snapshot   = true
  db_subnet_group_name    = aws_db_subnet_group.pg_subnet_group.name
  db_parameter_group_name = aws_db_parameter_group.db_pg.name
}

resource "aws_appautoscaling_target" "aurora_autoscaling" {
  count              = var.aurora_autoscaling.enabled ? 1 : 0
  service_namespace  = "rds"
  resource_id        = "cluster:${aws_rds_cluster.postgres_cluster.cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  min_capacity       = var.aurora_autoscaling.min_capacity
  max_capacity       = var.aurora_autoscaling.max_capacity
}


resource "aws_appautoscaling_policy" "aurora_scale_out" {
  count              = var.aurora_autoscaling.enabled ? 1 : 0
  name               = "aurora-scale-out"
  service_namespace  = aws_appautoscaling_target.aurora_autoscaling[0].service_namespace
  resource_id        = aws_appautoscaling_target.aurora_autoscaling[0].resource_id
  scalable_dimension = aws_appautoscaling_target.aurora_autoscaling[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = var.aurora_autoscaling.cpu_scale_out
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "aurora_scale_in" {
  count              = var.aurora_autoscaling.enabled ? 1 : 0
  name               = "aurora-scale-in"
  service_namespace  = aws_appautoscaling_target.aurora_autoscaling[0].service_namespace
  resource_id        = aws_appautoscaling_target.aurora_autoscaling[0].resource_id
  scalable_dimension = aws_appautoscaling_target.aurora_autoscaling[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = var.aurora_autoscaling.cpu_scale_in
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}


