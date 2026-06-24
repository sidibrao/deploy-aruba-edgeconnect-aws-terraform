variable "aws_region" {
  type        = string
  default     = "us-east-2"
  description = "AWS Region for the SD-WAN lab. Default is Ohio."
}

variable "name_prefix" {
  type        = string
  default     = "sdwan-v4"
  description = "Prefix used for Terraform-managed resource names. Use a unique value per deployment."
}

variable "project" {
  type        = string
  default     = "SD-WAN"
  description = "Project tag value."
}

variable "environment" {
  type        = string
  default     = "Production"
  description = "Default environment tag value."
}

variable "key_pair_name" {
  type        = string
  default     = "AWS-sid-EC-KP"
  description = "Existing EC2 key pair name for SSH access."
}

variable "restricted_ip" {
  type        = string
  default     = "184.147.66.76/32"
  description = "Admin IPv4 CIDR allowed to reach Aruba management interfaces."
}

variable "admin_email" {
  type        = string
  default     = ""
  description = "Optional email endpoint for SNS notifications. Leave blank to skip email subscription."
}

variable "compute_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for Compute ASG Linux web nodes."
}

variable "dev_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for static Dev Linux web servers."
}

variable "aruba_instance_type" {
  type        = string
  default     = "c5.xlarge"
  description = "Instance type for Aruba EdgeConnect / EC-V nodes."
}

variable "aruba_ami_id" {
  type        = string
  default     = "ami-02907b22e4a6ce1bd"
  description = "Aruba EC-V AMI ID for us-east-2. Update if the vendor publishes a newer AMI."
}

variable "alb_certificate_arn" {
  type        = string
  default     = ""
  description = "Optional ACM certificate ARN for HTTPS listener in the same region."
}

variable "backend_web_port" {
  type        = number
  default     = 80
  description = "Backend web server port used by the ALB target group and Lambda registration."
}

variable "target_registration_lambda_role_arn" {
  type        = string
  default     = ""
  description = "Optional existing IAM role ARN for the Lambda target-registration function. Leave blank to create one."
}

variable "hub_vpc_cidr" {
  type    = string
  default = "10.160.0.0/16"
}

variable "compute_vpc_cidr" {
  type    = string
  default = "10.161.0.0/16"
}

variable "dev_vpc_cidr" {
  type    = string
  default = "10.162.0.0/16"
}

variable "egress_vpc_cidr" {
  type    = string
  default = "10.163.0.0/16"
}
