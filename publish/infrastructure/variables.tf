# DRAFT - Review before applying

variable "domain_name" {
  description = "Primary domain name (apex, e.g., camdenwander.com)"
  type        = string
  default     = "camdenwander.com"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "index_document" {
  description = "Default root object for CloudFront"
  type        = string
  default     = "index.html"
}

variable "error_page_path" {
  description = "Path to custom error page for CloudFront error responses"
  type        = string
  default     = "/nope.html"
}

variable "enable_versioning" {
  description = "Enable S3 versioning for content bucket"
  type        = bool
  default     = true
}

variable "enable_security_headers" {
  description = "Enable CloudFront security headers response policy"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
