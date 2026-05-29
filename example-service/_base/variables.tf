# Base variables - defined ONCE
# All environments inherit these variable definitions via symlinks

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "example-app"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  # Default to Amazon Linux 2023 in us-east-1
  default = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "spot_price" {
  description = "Maximum spot price (empty string means on-demand price)"
  type        = string
  default     = "0.02"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {
    ManagedBy = "Terraform"
  }
}
