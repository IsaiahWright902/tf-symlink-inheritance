# Additional variables specific to production environment
# Only defined in prod - other environments don't see these
# Values come from TF Cloud workspace: example-service-prod

variable "alarm_email" {
  description = "Email address for production alerts"
  type        = string
}

variable "data_volume_size" {
  description = "Size of additional EBS volume in GB"
  type        = number
  default     = 100
}
