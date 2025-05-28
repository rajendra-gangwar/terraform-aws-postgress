variable "db_subnet_ids" {
  description = "subnet ids for database subnet group"
  type        = list(string)
}

variable "pg_version" {
  description = "Postgress database version"
  type        = string
}

variable "pg_storage" {
  description = "Allocated storage for the RDS instance"
  default     = 50
}

variable "pg_max_storage" {
  description = "Allocated storage for the RDS instance"
  default     = 100
}

variable "pg_instance" {
  description = "Instance class for the RDS instance"
  default     = "db.t3.medium"
}

variable "db_name" {
  description = "Name of the database"
  default     = "exampledb"
}

variable "pg_username" {
  description = "Master username for the database"
  default     = "admin"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window"
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  default     = "sun:04:00-sun:05:00"
}

variable "environment" {
  description = "Environment identifier (e.g., dev, staging, prod)"
  default     = "dev"
}

variable "vpc_id" {
  description = "Id of VPC ."
  type        = string
}


variable "db_instance_count" {
  description = "no of instance in database"
  type        = number
}

variable "rds_kms_key_id" {
  description = "custom kms key for rds"
  type        = string
  default     = null
}

variable "secretmanager_kms_key_id" {
  description = "custom kms key for secret manager"
  type        = string
  default     = null
}

variable "aurora_autoscaling" {
  description = "Aurora Auto Scaling Configuration"
  type = object({
    enabled       = bool
    cpu_scale_in  = number
    cpu_scale_out = number
    min_capacity  = number
    max_capacity  = number
  })
  default = {
    enabled       = false
    cpu_scale_in  = 50
    cpu_scale_out = 75
    min_capacity  = 1
    max_capacity  = 1
  }
}


variable "db_security_group_ids" {
  description = "security group ids for database"
  type        = list(string)
}
