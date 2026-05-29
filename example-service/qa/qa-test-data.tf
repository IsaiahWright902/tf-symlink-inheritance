# QA-specific test data generators
# Only exists in qa environment

resource "aws_s3_bucket" "test_data" {
  bucket = "${var.service_name}-${var.environment}-test-data"

  tags = merge(var.tags, {
    Purpose = "test-data-generation"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "test_data" {
  bucket = aws_s3_bucket.test_data.id

  rule {
    id     = "expire-test-data"
    status = "Enabled"

    expiration {
      days = 1  # Clean up test data daily
    }
  }
}

resource "aws_lambda_function" "test_data_generator" {
  function_name = "${var.service_name}-${var.environment}-test-data-generator"
  role          = aws_iam_role.test_data_lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  filename = "test_data_generator.zip"  # Would need to provide this

  environment {
    variables = {
      TEST_BUCKET = aws_s3_bucket.test_data.bucket
    }
  }

  tags = var.tags
}

resource "aws_iam_role" "test_data_lambda" {
  name = "${var.service_name}-${var.environment}-test-data-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

output "test_data_bucket" {
  description = "Test data bucket name"
  value       = aws_s3_bucket.test_data.bucket
}
