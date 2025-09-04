data "aws_caller_identity" "current" {}

module "opensearch" {
  source = "terraform-aws-modules/opensearch/aws"

  # Domain
  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  advanced_security_options = {
    enabled                        = false
    anonymous_auth_enabled         = true
    internal_user_database_enabled = true

    master_user_options = {
      master_user_name     = "root"
      master_user_password = "Barbera4!"
    }
  }

  auto_tune_options = {
    desired_state = "DISABLED"

    maintenance_schedule = [
      {
        start_at                       = "2028-05-13T07:44:12Z"
        cron_expression_for_recurrence = "cron(0 0 ? * 1 *)"
        duration = {
          value = "2"
          unit  = "HOURS"
        }
      }
    ]

    rollback_on_disable = "NO_ROLLBACK"
  }

  cluster_config = {
    instance_count           = 3
    dedicated_master_enabled = false
#     dedicated_master_type    = "t3.small.search"
    instance_type            = "t3.medium.search"

    zone_awareness_config = {
      availability_zone_count = 3
    }


    zone_awareness_enabled = true
  }

  domain_endpoint_options = {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  domain_name = var.opensearch_domain_name

  ebs_options = {
    ebs_enabled = true
    iops        = 3000
    throughput  = 125
    volume_type = "gp3"
    volume_size = 20
  }

  encrypt_at_rest = {
    enabled = true
  }

  engine_version = "OpenSearch_2.11"

  log_publishing_options = [
    { log_type = "INDEX_SLOW_LOGS" },
    { log_type = "SEARCH_SLOW_LOGS" },
  ]

  node_to_node_encryption = {
    enabled = true
  }

  software_update_options = {
    auto_software_update_enabled = true
  }

#   vpc_options = {
#     security_group_ids = [aws_security_group.opensearch_sg.id]
#     subnet_ids = data.aws_subnets.private_subnets.*.ids[0]
#   }

#   # VPC endpoint
#   vpc_endpoints = {
#     one = {
#       subnet_ids = data.aws_subnets.private_subnets.*.ids[0]
#
#     }
#   }

  # Access policy
  access_policies = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "es:*",
        "Resource": "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain_name}/*",
        "Condition": {
          "IpAddress": {
            "aws:SourceIp": concat([for s in data.aws_subnet.all_subnet : s.cidr_block],["54.81.197.204/32"])  # Allow access from all subnets
          }
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


resource "aws_security_group" "opensearch_sg" {
  name        = "opensearch-sg"
  description = "Security group for OpenSearch domain"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with your allowed IP range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


