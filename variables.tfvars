####### database related values

pg_storage            = 50
pg_max_storage        = 100
pg_version            = 16
pg_instance           = "db.t3.medium"
db_name               = "db"
pg_username           = "dbuser"
backup_retention_days = 7
backup_window         = "03:00-04:00"
maintenance_window    = "sun:04:00-sun:05:00"
db_instance_count     = 1

db_auto_scaling = {
  enabled       = false
  cpu_scale_in  = 50
  cpu_scale_out = 75
  min_capacity  = 1
  max_capacity  = 1
}


# security group

alb_ingress_rules = [
  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  },
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }
]
