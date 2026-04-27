locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"

  # Build the subject claim conditions for branch-scoped access
  # Format: repo:ORG/REPO:ref:refs/heads/BRANCH
  subject_claims = [
    for branch in var.allowed_branches :
    "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
  ]

  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "github-oidc"
  })
}

# =============================================================================
# OIDC Identity Provider
# Only create if it doesn't already exist (one per AWS account)
# =============================================================================

data "aws_iam_openid_connect_provider" "existing" {
  count = 1
  url   = local.github_oidc_url
}

resource "aws_iam_openid_connect_provider" "github" {
  count = length(data.aws_iam_openid_connect_provider.existing) == 0 ? 1 : 0

  url             = local.github_oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = local.common_tags
}

locals {
  oidc_provider_arn = length(data.aws_iam_openid_connect_provider.existing) > 0 ? data.aws_iam_openid_connect_provider.existing[0].arn : aws_iam_openid_connect_provider.github[0].arn
}

# =============================================================================
# IAM Role with OIDC Trust Policy
# =============================================================================

resource "aws_iam_role" "github_actions" {
  name                 = var.role_name
  max_session_duration = var.max_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(local.github_oidc_url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "${replace(local.github_oidc_url, "https://", "")}:sub" = local.subject_claims
        }
      }
    }]
  })

  tags = merge(local.common_tags, {
    GitHubOrg  = var.github_org
    GitHubRepo = var.github_repo
  })
}

# =============================================================================
# Policy Attachments
# =============================================================================

resource "aws_iam_role_policy_attachment" "managed" {
  count = length(var.policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = var.policy_arns[count.index]
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy != "" ? 1 : 0

  name   = "${var.role_name}-inline"
  role   = aws_iam_role.github_actions.id
  policy = var.inline_policy
}
