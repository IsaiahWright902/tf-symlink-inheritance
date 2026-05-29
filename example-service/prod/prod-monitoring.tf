# Prod-specific enhanced monitoring
# Only exists in prod environment

# SNS topic for production alerts
resource "aws_sns_topic" "prod_alerts" {
  name = "${var.service_name}-${var.environment}-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "prod_alerts_email" {
  topic_arn = aws_sns_topic.prod_alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CPU utilization alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.service_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when CPU utilization is high"
  alarm_actions       = [aws_sns_topic.prod_alerts.arn]

  dimensions = {
    InstanceId = aws_spot_instance_request.app.spot_instance_id
  }
}

# CloudWatch log group with longer retention for prod
resource "aws_cloudwatch_log_group" "prod_logs" {
  name              = "/aws/${var.service_name}/${var.environment}/app"
  retention_in_days = 30  # Longer retention than dev

  tags = var.tags
}
