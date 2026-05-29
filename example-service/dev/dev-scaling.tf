# Dev-specific configuration
# This file only exists in the dev environment
# Can use all base variables (they're symlinked)

# Dev uses a cheaper instance type
# This shows how you can override behavior without changing base
resource "aws_cloudwatch_log_group" "dev_debug" {
  name              = "/aws/${var.service_name}/${var.environment}/debug"
  retention_in_days = 3  # Short retention for dev

  tags = merge(var.tags, {
    Purpose = "Development debugging"
  })
}
