# QA-specific additions
# This file sits alongside symlinked base files
# Can use all base variables (they're symlinked)

resource "aws_sqs_queue" "debug" {
  name                      = "${var.service_name}-${var.environment}-debug-queue"
  message_retention_seconds = 86400

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "debug" {
  name              = "/aws/${var.service_name}/${var.environment}/debug"
  retention_in_days = 7

  tags = var.tags
}
