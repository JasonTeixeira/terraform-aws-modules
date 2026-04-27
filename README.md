# terraform-aws-modules

Production-ready Terraform modules for AWS infrastructure. Opinionated, tested, and designed for teams that ship.

```
┌─────────────────────────────────────────────────────────────────┐
│  4 modules  •  CI-tested  •  Variable validation  •  Examples   │
│                                                                 │
│  VPC        S3 Static Site    Lambda API    GitHub OIDC         │
│  ───────    ──────────────    ──────────    ───────────         │
│  Multi-AZ   CloudFront CDN   API Gateway   Keyless CI/CD       │
│  NAT/IGW    ACM + HTTPS      Custom domain No static keys      │
│  Flow logs  Cache policy      Logging       Branch-scoped       │
└─────────────────────────────────────────────────────────────────┘
```

## Why This Exists

I built these modules after deploying AWS infrastructure across multiple projects (including a [fintech platform with 185 database tables](https://sageideas.dev/case-studies/nexural-ecosystem)). Every project needed the same foundational pieces — VPC, static hosting, serverless API, CI/CD auth — and I was copy-pasting HCL between repos.

These modules encode the patterns I use in production. They're opinionated by design.

## Modules

### [`vpc`](./modules/vpc/) — Multi-AZ VPC with Public & Private Subnets

Creates a production VPC with:
- Public and private subnets across 2-3 AZs
- Internet Gateway + NAT Gateway (optional, cost-controlled)
- VPC Flow Logs to CloudWatch (optional)
- DNS hostnames and resolution enabled
- Consistent tagging with `ManagedBy = terraform`

```hcl
module "vpc" {
  source = "./modules/vpc"

  name               = "nexural-prod"
  cidr               = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  enable_nat_gateway = true
  enable_flow_logs   = true

  tags = {
    Environment = "production"
    Project     = "nexural"
  }
}
```

### [`s3-static-site`](./modules/s3-static-site/) — S3 + CloudFront Static Hosting

Deploys a static website with:
- S3 bucket with versioning and encryption
- CloudFront distribution with HTTPS (ACM certificate)
- Origin Access Identity (no public S3 bucket)
- Cache behavior optimized for SPAs (index.html fallback)
- Optional WAF integration

```hcl
module "static_site" {
  source = "./modules/s3-static-site"

  domain_name      = "docs.sageideas.dev"
  certificate_arn  = aws_acm_certificate.cert.arn
  index_document   = "index.html"
  error_document   = "404.html"
  enable_waf       = true

  tags = {
    Environment = "production"
    Project     = "sageideas"
  }
}
```

### [`lambda-api`](./modules/lambda-api/) — Lambda + API Gateway REST API

Creates a serverless API with:
- Lambda function with configurable runtime, memory, timeout
- API Gateway HTTP API with custom domain (optional)
- CloudWatch log group with retention policy
- IAM role with least-privilege policy
- Environment variables for configuration
- CORS configuration

```hcl
module "api" {
  source = "./modules/lambda-api"

  function_name = "nexural-telemetry"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  source_dir    = "${path.module}/src"
  memory_size   = 256
  timeout       = 30

  environment_variables = {
    METRICS_BUCKET = module.static_site.bucket_name
    API_TOKEN      = var.api_token
  }

  # Optional custom domain
  domain_name     = "api.sageideas.dev"
  certificate_arn = aws_acm_certificate.cert.arn

  tags = {
    Environment = "production"
  }
}
```

### [`github-oidc`](./modules/github-oidc/) — GitHub Actions OIDC Federation

Enables keyless CI/CD with:
- OIDC identity provider for GitHub Actions
- IAM role with trust policy scoped to repo + branch
- Configurable policy attachments
- No long-lived AWS credentials anywhere

```hcl
module "github_oidc" {
  source = "./modules/github-oidc"

  role_name          = "GitHubActions-Deploy"
  github_org         = "JasonTeixeira"
  github_repo        = "qa-portfolio"
  allowed_branches   = ["main"]

  policy_arns = [
    "arn:aws:iam::policy/S3DeployPolicy",
    "arn:aws:iam::policy/CloudFrontInvalidation",
  ]

  tags = {
    Environment = "ci"
    ManagedBy   = "terraform"
  }
}
```

## Architecture

```
                    GitHub Actions (OIDC)
                           │
                    ┌──────┴──────┐
                    │  IAM Role   │  (github-oidc module)
                    │  No keys    │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────┴─────┐ ┌───┴────┐ ┌────┴─────┐
        │    VPC     │ │   S3   │ │  Lambda  │
        │ Multi-AZ   │ │ + CDN  │ │  + APIGW │
        │ Pub/Priv   │ │ HTTPS  │ │  Custom  │
        │ NAT/IGW    │ │ WAF    │ │  Domain  │
        └───────────┘ └────────┘ └──────────┘
         (vpc module)  (s3-static  (lambda-api
                        -site)      module)
```

## Usage

```bash
# Clone
git clone https://github.com/JasonTeixeira/terraform-aws-modules.git
cd terraform-aws-modules

# Use a module in your project
module "vpc" {
  source = "github.com/JasonTeixeira/terraform-aws-modules//modules/vpc"
  # ... variables
}

# Or copy the module directory into your project
cp -r modules/vpc /your-project/infra/modules/
```

## Module Design Principles

1. **Every variable has a description and type constraint.** No guessing what inputs are expected.
2. **Every variable with a sensible default has one.** Minimal required inputs.
3. **Every output has a description.** Modules are APIs — outputs are the interface.
4. **Validation blocks catch errors early.** CIDR format, naming conventions, region patterns.
5. **Tags are non-negotiable.** Every resource gets `ManagedBy`, `Module`, and user-supplied tags.
6. **Least privilege by default.** IAM policies grant minimum permissions. No wildcards.
7. **Cost awareness built in.** NAT Gateway is optional (it's $32/month). Flow logs are optional. Nothing expensive is on by default without explicit opt-in.

## CI/CD

Every push runs:
- `terraform fmt -check` — consistent formatting
- `terraform validate` — syntax and type checking
- `tflint` — best practice linting
- `checkov` — security scanning (CIS benchmarks)
- `terraform plan` on examples — proves modules are deployable

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5 |
| AWS Provider | >= 5.0 |

## Author

**Jason Teixeira** — [sageideas.dev](https://sageideas.dev) | [GitHub](https://github.com/JasonTeixeira)

Built from patterns used in production across fintech platforms, portfolio sites, and trading infrastructure.
