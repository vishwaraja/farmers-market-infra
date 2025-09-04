# =============================================================================
# BACKEND MODULE - MICROSERVICES DEPLOYMENT
# =============================================================================
# This module creates infrastructure for backend microservices including:
# - Application Load Balancer for API Gateway
# - EKS cluster for microservices
# - Service mesh configuration (optional)
# - Monitoring and logging setup

# Application Load Balancer for API Gateway
resource "aws_lb" "api_gateway" {
  name               = "${var.name_prefix}-api-gateway"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-gateway-alb"
    Type = "backend"
  })
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for API Gateway ALB"

  # Allow HTTP traffic from anywhere
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from anywhere
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group for API Gateway
resource "aws_lb_target_group" "api_gateway" {
  name     = "${var.name_prefix}-api-gateway"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-gateway-tg"
  })
}

# ALB Listener for HTTP (redirects to HTTPS)
resource "aws_lb_listener" "api_gateway_http" {
  load_balancer_arn = aws_lb.api_gateway.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener for HTTPS
resource "aws_lb_listener" "api_gateway_https" {
  count = var.ssl_certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.api_gateway.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway.arn
  }
}

# ALB Listener for HTTPS (without SSL certificate - for dev)
resource "aws_lb_listener" "api_gateway_https_dev" {
  count = var.ssl_certificate_arn == null ? 1 : 0

  load_balancer_arn = aws_lb.api_gateway.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.api_gateway[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway.arn
  }
}

# ACM Certificate for HTTPS (dev environment)
resource "aws_acm_certificate" "api_gateway" {
  count = var.ssl_certificate_arn == null ? 1 : 0

  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = [
    var.domain_name
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-gateway-cert"
  })
}

# ACM Certificate Validation (dev environment)
resource "aws_acm_certificate_validation" "api_gateway" {
  count = var.ssl_certificate_arn == null ? 1 : 0

  certificate_arn         = aws_acm_certificate.api_gateway[0].arn
  validation_record_fqdns = [for record in aws_route53_record.api_gateway_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# Route53 Record for Certificate Validation (dev environment)
resource "aws_route53_record" "api_gateway_validation" {
  count = var.ssl_certificate_arn == null && var.hosted_zone_id != null ? 1 : 0

  for_each = {
    for dvo in aws_acm_certificate.api_gateway[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# Route53 Record for API Gateway (optional)
resource "aws_route53_record" "api_gateway" {
  count = var.hosted_zone_id != null ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.api_gateway.dns_name
    zone_id                = aws_lb.api_gateway.zone_id
    evaluate_target_health = true
  }
}

# CloudWatch Log Group for ALB
resource "aws_cloudwatch_log_group" "alb" {
  name              = "/aws/applicationloadbalancer/${var.name_prefix}-api-gateway"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-logs"
  })
}

# ALB Access Logs
resource "aws_s3_bucket" "alb_logs" {
  count = var.enable_alb_logs ? 1 : 0

  bucket = "${var.name_prefix}-alb-logs-${random_string.bucket_suffix[0].result}"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-logs-bucket"
  })
}

resource "random_string" "bucket_suffix" {
  count = var.enable_alb_logs ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count = var.enable_alb_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"  # ALB service account
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs[0].arn
      }
    ]
  })
}
