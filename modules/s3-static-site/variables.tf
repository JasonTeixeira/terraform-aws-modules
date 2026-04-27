variable "domain_name" {
  description = "Domain name for the static site (e.g., docs.sageideas.dev)"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (must be in us-east-1 for CloudFront)"
  type        = string
}

variable "index_document" {
  description = "Index document for the S3 website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for the S3 website (SPA fallback)"
  type        = string
  default     = "index.html"
}

variable "enable_waf" {
  description = "Enable AWS WAF with rate limiting on the CloudFront distribution"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Maximum requests per 5-minute window per IP (WAF rate limiting)"
  type        = number
  default     = 1000
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100 = US/EU only, cheapest)"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
