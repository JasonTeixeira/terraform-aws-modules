variable "function_name" {
  description = "Name of the Lambda function"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.function_name))
    error_message = "Function name must be 1-64 characters, alphanumeric with hyphens and underscores."
  }
}

variable "runtime" {
  description = "Lambda runtime (e.g., nodejs20.x, python3.12)"
  type        = string
  default     = "nodejs20.x"

  validation {
    condition     = can(regex("^(nodejs|python|java|dotnet|ruby)", var.runtime))
    error_message = "Must be a valid Lambda runtime."
  }
}

variable "handler" {
  description = "Lambda handler (e.g., index.handler)"
  type        = string
  default     = "index.handler"
}

variable "source_dir" {
  description = "Path to the directory containing the Lambda source code"
  type        = string
}

variable "memory_size" {
  description = "Lambda memory in MB (128-10240)"
  type        = number
  default     = 256

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory must be between 128 and 10240 MB."
  }
}

variable "timeout" {
  description = "Lambda timeout in seconds (1-900)"
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "domain_name" {
  description = "Optional custom domain for the API (e.g., api.sageideas.dev)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain HTTPS"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "cors_allow_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "additional_iam_statements" {
  description = "Additional IAM policy statements for the Lambda role (JSON list)"
  type        = string
  default     = "[]"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
