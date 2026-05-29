# Base infrastructure - ALL environments get this via symlink
# Edit this file ONCE, all environments inherit the changes

# Spot instance request for cost-effective compute
resource "aws_spot_instance_request" "app" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  spot_price           = var.spot_price
  wait_for_fulfillment = true

  tags = merge(var.tags, {
    Name        = "${var.service_name}-${var.environment}"
    Environment = var.environment
  })
}

# Security group for the instance
resource "aws_security_group" "app" {
  name        = "${var.service_name}-${var.environment}-sg"
  description = "Security group for ${var.service_name} ${var.environment}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = var.tags
}

# Output the instance details
output "instance_id" {
  description = "ID of the spot instance"
  value       = aws_spot_instance_request.app.spot_instance_id
}

output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_spot_instance_request.app.public_ip
}
