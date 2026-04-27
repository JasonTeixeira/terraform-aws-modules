locals {
  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "rds-postgres"
  })
}

# =============================================================================
# Random password for master user (stored in Secrets Manager)
# =============================================================================

resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.identifier}-db-password"
  description = "Master password for ${var.identifier} RDS instance"
  tags        = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    database = var.database_name
  })
}

# =============================================================================
# DB Subnet Group
# =============================================================================

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.identifier}-subnet-group"
  })
}

# =============================================================================
# Security Group
# =============================================================================

resource "aws_security_group" "postgres" {
  name_prefix = "${var.identifier}-db-"
  description = "Security group for ${var.identifier} RDS instance"
  vpc_id      = var.vpc_id

  # PostgreSQL port from allowed CIDRs
  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
      description = "PostgreSQL from allowed CIDRs"
    }
  }

  # PostgreSQL port from allowed security groups
  dynamic "ingress" {
    for_each = var.allowed_security_groups
    content {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "PostgreSQL from allowed SG"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(local.common_tags, {
    Name = "${var.identifier}-db-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# RDS Instance
# =============================================================================

resource "aws_db_instance" "postgres" {
  identifier = var.identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2  # Auto-scaling up to 2x
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  publicly_accessible    = var.publicly_accessible

  multi_az                     = var.multi_az
  backup_retention_period      = var.backup_retention_period
  backup_window                = "03:00-04:00"
  maintenance_window           = "sun:04:00-sun:05:00"
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = !var.deletion_protection
  final_snapshot_identifier    = var.deletion_protection ? "${var.identifier}-final-snapshot" : null
  performance_insights_enabled = var.performance_insights_enabled
  copy_tags_to_snapshot        = true

  # Parameter group for tuning
  parameter_group_name = aws_db_parameter_group.postgres.name

  tags = merge(local.common_tags, {
    Name = var.identifier
  })
}

# =============================================================================
# Parameter Group (PostgreSQL tuning)
# =============================================================================

resource "aws_db_parameter_group" "postgres" {
  family = "postgres16"
  name   = "${var.identifier}-params"

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries taking > 1 second
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = local.common_tags
}
