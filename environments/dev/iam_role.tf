resource "aws_iam_role" "service_role" {
  name = "k8s-service-role"

  # Attach specific IAM policies based on your service's needs
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Define IAM policies for specific permissions (DynamoDB example)
resource "aws_iam_policy" "dynamodb_access" {
  name = "dynamodb-access-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:*"
      ],
      "Resource": [
        "arn:aws:dynamodb:us-east-1:975050144940:table/*"
      ]
    }
  ]
}
EOF
}

# Attach policy to the role
resource "aws_iam_role_policy_attachment" "dynamodb_access_attachment" {
  role       = aws_iam_role.service_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Output the role ARN for use in k8s configuration
output "iam_role_arn" {
  value = aws_iam_role.service_role.arn
}