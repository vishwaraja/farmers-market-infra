resource "aws_iam_role" "bastion" {
  name = "bastion-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

}

# Define a policy that grants full access to all resources and actions on AWS
resource "aws_iam_policy" "full_access_policy" {
  name        = "FullAccessPolicy"
  path        = "/"
  description = "Policy that grants full access to all resources and actions on AWS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "*",
        Resource = "*"
      }
    ]
  })
}

# Attach the full access policy to the bastion IAM role
resource "aws_iam_role_policy_attachment" "bastion_full_access_policy_attachment" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.full_access_policy.arn
}

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion-instance-profile"
  role = aws_iam_role.bastion.name
}

module "bastion_host" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "4.0.0"

  name                        = "bastion"
  subnet_id                   = element(module.vpc.public_subnets, 0)
  instance_type               = "t2.micro"
  ami                         = "ami-0195204d5dce06d99"
  key_name                    = "bastion-ssh"
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  tags                        =  {
                                  Terraform = "true"
                                  Environment = "dev"
                                  Type = "bastion"
                                }
}

resource "aws_security_group" "bastion_sg" {
  name = "bastion-security-group"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id


  ingress {
    from_port = 22
    to_port   = 22
    protocol = "tcp"
    cidr_blocks = var.vpn_ip_ranges  # Replace with your allowed IP range
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

