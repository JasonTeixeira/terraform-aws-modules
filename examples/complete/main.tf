# =============================================================================
# Complete Example: VPC + Static Site + Lambda API + GitHub OIDC
# =============================================================================
#
# This example deploys the full infrastructure stack:
# - Multi-AZ VPC with public/private subnets
# - S3 + CloudFront static site with HTTPS and WAF
# - Lambda + API Gateway serverless API
# - GitHub Actions OIDC for keyless CI/CD deployments
#
# Usage:
#   cd examples/complete
#   cp terraform.tfvars.example terraform.tfvars
#   # Edit terraform.tfvars with your values
#   terraform init
#   terraform plan
#   terraform apply

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "my-project"
}

variable "domain_name" {
  description = "Domain for the static site"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1)"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

# Common tags for all resources
locals {
  tags = {
    Project     = var.project_name
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# VPC
# =============================================================================

module "vpc" {
  source = "../../modules/vpc"

  name               = var.project_name
  cidr               = "10.0.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  enable_nat_gateway = false  # Save $32/month — enable when needed
  enable_flow_logs   = true

  tags = local.tags
}

# =============================================================================
# Static Site
# =============================================================================

module "static_site" {
  source = "../../modules/s3-static-site"

  domain_name     = var.domain_name
  certificate_arn = var.certificate_arn
  enable_waf      = true
  waf_rate_limit  = 1000

  tags = local.tags
}

# =============================================================================
# Lambda API
# =============================================================================

module "api" {
  source = "../../modules/lambda-api"

  function_name = "${var.project_name}-api"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  source_dir    = "${path.module}/src"
  memory_size   = 256
  timeout       = 30

  environment_variables = {
    BUCKET_NAME = module.static_site.bucket_name
    NODE_ENV    = "production"
  }

  cors_allow_origins = ["https://${var.domain_name}"]

  # Grant the Lambda read access to the S3 bucket
  additional_iam_statements = jsonencode([{
    Effect   = "Allow"
    Action   = ["s3:GetObject"]
    Resource = "${module.static_site.bucket_arn}/*"
  }])

  tags = local.tags
}

# =============================================================================
# GitHub OIDC (Keyless CI/CD)
# =============================================================================

module "github_oidc" {
  source = "../../modules/github-oidc"

  role_name        = "${var.project_name}-deploy"
  github_org       = var.github_org
  github_repo      = var.github_repo
  allowed_branches = ["main"]

  # Grant deploy permissions
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3Deploy"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          module.static_site.bucket_arn,
          "${module.static_site.bucket_arn}/*",
        ]
      },
      {
        Sid      = "CloudFrontInvalidate"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = "arn:aws:cloudfront::*:distribution/${module.static_site.cloudfront_distribution_id}"
      },
      {
        Sid      = "LambdaDeploy"
        Effect   = "Allow"
        Action   = ["lambda:UpdateFunctionCode"]
        Resource = module.api.function_arn
      },
    ]
  })

  tags = local.tags
}

# =============================================================================
# Outputs
# =============================================================================

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "website_url" {
  value = module.static_site.website_url
}

output "api_endpoint" {
  value = module.api.api_endpoint
}

output "github_role_arn" {
  value = module.github_oidc.role_arn
}
