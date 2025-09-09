# =============================================================================
# BEST PRACTICES COMPLIANCE TESTS
# =============================================================================
# This file contains best practices compliance tests for Terraform infrastructure

Feature: Best Practices Compliance
  Scenario: Resources should have proper tags
    Given I have aws_s3_bucket defined
    Then it must have tags
    And it must have tags.Environment
    And it must have tags.Project
    And it must have tags.ManagedBy

  Scenario: EKS clusters should have proper version
    Given I have aws_eks_cluster defined
    Then it must have version
    And it must not have version.1.20
    And it must not have version.1.21

  Scenario: EKS node groups should have proper instance types
    Given I have aws_eks_node_group defined
    Then it must have instance_types
    And it must not have instance_types.t2.micro
    And it must not have instance_types.t2.nano

  Scenario: Security groups should have proper naming
    Given I have aws_security_group defined
    Then it must have name
    And it must not have name.default
    And it must not have name.allow_all

  Scenario: S3 buckets should have proper naming
    Given I have aws_s3_bucket defined
    Then it must have bucket
    And it must not have bucket.default
    And it must not have bucket.test

  Scenario: EKS clusters should have proper logging
    Given I have aws_eks_cluster defined
    Then it must have enabled_cluster_log_types
    And it must have enabled_cluster_log_types.api
    And it must have enabled_cluster_log_types.audit

  Scenario: EKS node groups should have proper scaling
    Given I have aws_eks_node_group defined
    Then it must have scaling_config
    And it must have scaling_config.desired_size
    And it must have scaling_config.max_size
    And it must have scaling_config.min_size
