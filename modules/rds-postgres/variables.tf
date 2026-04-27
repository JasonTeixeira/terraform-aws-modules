variable "identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.identifier))
    error_message = "Identifier must be lowercase alphanumeric with hyphens, max 63 chars."
  }
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "RDS instance class (e.g., db.t4g.micro for free tier)"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "Storage must be between 20 and 65536 GB."
  }
}

variable "database_name" {
  description = "Name of the default database"
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

variable "vpc_id" {
  description = "VPC ID where the database will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (use private subnets)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets required for high availability."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "Security group IDs allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability. Doubles cost."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0 to disable)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention must be between 0 and 35 days."
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection (prevents accidental terraform destroy)"
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights for query analysis"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Make the database publicly accessible. DANGEROUS — use only for development."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
