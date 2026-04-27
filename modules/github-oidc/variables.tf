variable "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_+=,.@-]{0,63}$", var.role_name))
    error_message = "Role name must be a valid IAM role name (1-64 chars, alphanumeric + special chars)."
  }
}

variable "github_org" {
  description = "GitHub organization or username (e.g., 'JasonTeixeira')"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g., 'qa-portfolio')"
  type        = string
}

variable "allowed_branches" {
  description = "List of branches allowed to assume this role (e.g., ['main', 'production'])"
  type        = list(string)
  default     = ["main"]

  validation {
    condition     = length(var.allowed_branches) > 0
    error_message = "At least one branch must be allowed."
  }
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policy" {
  description = "Optional inline IAM policy JSON document"
  type        = string
  default     = ""
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds (1-12 hours)"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Session duration must be between 3600 (1 hour) and 43200 (12 hours)."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
