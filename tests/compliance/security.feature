# =============================================================================
# SECURITY COMPLIANCE TESTS
# =============================================================================
# This file contains security compliance tests for Terraform infrastructure

Feature: Security Compliance
  Scenario: S3 buckets should be encrypted
    Given I have aws_s3_bucket defined
    Then it must have server_side_encryption_configuration
    And it must have server_side_encryption_configuration.rule
    And it must have server_side_encryption_configuration.rule.apply_server_side_encryption_by_default

  Scenario: S3 buckets should not be public
    Given I have aws_s3_bucket defined
    Then it must not have public_access_block
    And it must not have public_access_block.block_public_acls
    And it must not have public_access_block.block_public_acls.false

  Scenario: Security groups should not allow all traffic
    Given I have aws_security_group defined
    Then it must not have ingress
    And it must not have ingress.cidr_blocks
    And it must not have ingress.cidr_blocks.0.0.0.0/0

  Scenario: EKS clusters should be encrypted
    Given I have aws_eks_cluster defined
    Then it must have encryption_config
    And it must have encryption_config.provider
    And it must have encryption_config.provider.key_arn

  Scenario: RDS instances should be encrypted
    Given I have aws_db_instance defined
    Then it must have storage_encrypted
    And it must have storage_encrypted.true

  Scenario: EBS volumes should be encrypted
    Given I have aws_ebs_volume defined
    Then it must have encrypted
    And it must have encrypted.true

  Scenario: Lambda functions should be encrypted
    Given I have aws_lambda_function defined
    Then it must have kms_key_arn
    And it must not have kms_key_arn.null
