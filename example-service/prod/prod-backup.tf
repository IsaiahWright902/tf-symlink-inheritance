# Prod-specific additions
# This file only exists in prod environment
# Can use all base variables (they're symlinked via variables.tf)

# Additional EBS volume for prod data persistence
resource "aws_ebs_volume" "data" {
  availability_zone = "${var.region}a"
  size              = var.data_volume_size
  encrypted         = true

  tags = merge(var.tags, {
    Name = "${var.service_name}-${var.environment}-data"
    Backup = "daily"
  })
}

# CloudWatch alarm for disk space
resource "aws_cloudwatch_metric_alarm" "disk_space" {
  alarm_name          = "${var.service_name}-${var.environment}-disk-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DiskSpaceAvailable"
  namespace           = "System/Linux"
  period              = 300
  statistic           = "Average"
  threshold           = 1024  # 1GB
  alarm_description   = "Alert when disk space is low"

  dimensions = {
    InstanceId = aws_spot_instance_request.app.spot_instance_id
  }
}
