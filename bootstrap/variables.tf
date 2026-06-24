variable "aws_region" {
  type        = string
  default     = "us-east-2"
  description = "AWS Region for the Terraform state bucket."
}

variable "state_bucket_name" {
  type        = string
  default     = "ec-sdwan-aws-s3"
  description = "Globally unique S3 bucket name for Terraform remote state."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "Use a valid S3 bucket name with 3-63 lowercase letters, numbers, dots, or hyphens."
  }
}

variable "state_key" {
  type        = string
  default     = "sdwan/v4/terraform.tfstate"
  description = "S3 object key used by the main deployment state."
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "SD-WAN"
    Environment = "Bootstrap"
    ManagedBy   = "Terraform"
  }
  description = "Tags applied to bootstrap resources."
}
