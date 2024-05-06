variable "bucket" {
  description = "S3 bucket holding common crawl information"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment all resources will be built"
  type        = string
  default     = null
}

variable "region" {
  description = "AWS Region where resources will be deployed"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

variable "terraform_aws_iam_role" {
  description = "IAM role assumed to create and destroy with terraform"
  type        = string
  default     = ""
}