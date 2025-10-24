---
name: iac
description: Infrastructure as Code expertise using Terraform for major cloud providers (AWS, Azure, GCP).
inputs: { dir: optional, workspace: optional, provider: optional }
outputs: { terraform_code: hcl, plan_summary: markdown }
dependencies: [ terraform, cloud provider CLI tools ]
safety: Follow best practices; escalate for ignore_changes usage.
steps:
  - Use Terraform best practices for infrastructure provisioning.
  - Leverage provider-specific patterns for AWS, Azure, GCP.
  - Ensure resource naming follows conventions.
  - Use data sources over hardcoded values where possible.
  - Implement proper resource dependencies.
  - Follow security best practices (encryption, least privilege).
tooling:
  - commands: terraform init/plan/apply
  - cloud CLIs: aws, az, gcloud
  - make/task targets for terraform operations
---

# Infrastructure as Code (IaC) Skill

## Overview
This skill provides expertise in writing, reviewing, and maintaining Infrastructure as Code using Terraform for major cloud providers including AWS, Azure, and GCP.

## Core Principles

### Terraform Best Practices
- **Module Structure**: Organize code into reusable modules with clear inputs/outputs
- **State Management**: Use remote state backends with proper locking
- **Resource Naming**: Follow consistent naming conventions (kebab-case or underscore_case)
- **Variables**: Use typed variables with descriptions and sensible defaults
- **Outputs**: Expose useful outputs for downstream consumption
- **Documentation**: Document module usage, requirements, and examples

### Provider-Specific Patterns

#### AWS
- Use latest AWS provider features
- Leverage data sources (aws_ami, aws_availability_zones, etc.)
- Follow AWS Well-Architected Framework principles
- Use tags consistently for cost allocation and organization
- Prefer managed services over self-managed infrastructure

#### Azure
- Use azurerm provider with proper authentication
- Leverage resource groups for logical organization
- Use Azure naming conventions
- Implement Azure policies and RBAC
- Use managed identities where applicable

#### GCP
- Use google provider with proper project configuration
- Leverage GCP organizational hierarchy
- Follow GCP security best practices
- Use service accounts with minimal permissions
- Implement proper IAM bindings

### Security Best Practices
- **Encryption**: Enable encryption at rest and in transit
- **Least Privilege**: Grant minimal required permissions
- **Network Security**: Use security groups, NACLs, firewalls appropriately
- **Secrets Management**: Never hardcode secrets; use secret managers
- **Logging**: Enable audit logging and monitoring
- **Compliance**: Follow industry standards (CIS, PCI-DSS, etc.)

## Critical Safety Rule: lifecycle.ignore_changes

**IMPORTANT**: The `lifecycle.ignore_changes` argument should **NEVER** be added or extended in Terraform code without explicit user approval.

### Why This Matters
- `ignore_changes` masks configuration drift between code and actual infrastructure
- It leads to confusing problems where Terraform shows "no changes" but infrastructure differs
- It often indicates a deeper problem with resource configuration or dependencies
- It makes infrastructure state unpredictable and harder to maintain
- It violates the principle of infrastructure-as-code where code should be source of truth

### What To Do Instead
When encountering a situation where `ignore_changes` seems necessary:

1. **Identify the Root Cause**: Why is Terraform detecting unwanted changes?
   - External systems modifying resources?
   - Incorrect resource configuration?
   - Missing data source or computed value?
   - Timing or ordering issue?

2. **Propose Better Solutions**:
   - Use `lifecycle.create_before_destroy` for replacement order issues
   - Use data sources for values managed elsewhere
   - Separate resources managed by different systems
   - Use proper dependencies with `depends_on`
   - Leverage `lifecycle.prevent_destroy` for critical resources
   - Import existing resources instead of ignoring drift

3. **Escalate to User**: Before adding `ignore_changes`:
   - Explain the problem being encountered
   - Describe why the resource is showing unwanted changes
   - Propose alternative solutions
   - Request explicit approval if `ignore_changes` is truly the only option

### Example
```hcl
# BAD - Do not add without approval
resource "aws_instance" "example" {
  # ...
  lifecycle {
    ignore_changes = [tags]  # This hides tag drift!
  }
}

# GOOD - Address the root cause
resource "aws_instance" "example" {
  # ...
  # Let Terraform manage all tags to maintain consistency
  tags = merge(
    var.common_tags,
    {
      Name = "example-instance"
    }
  )
}
```

## Code Quality Guidelines

### Resource Configuration
- Use descriptive resource names: `aws_instance.web_server` not `aws_instance.x`
- Group related resources in logical files
- Use count or for_each for multiple similar resources
- Implement proper error handling with validation blocks

### Variable Management
```hcl
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### Output Management
```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.example.id
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.example.private_ip
  sensitive   = false
}
```

### Documentation
- Include README.md in each module with:
  - Purpose and usage
  - Requirements (terraform version, providers)
  - Input variables table
  - Output values table
  - Example usage
- Use inline comments for complex logic
- Document any non-obvious decisions or workarounds

## Testing and Validation

### Pre-Apply Checks
- Run `terraform fmt` to ensure consistent formatting
- Run `terraform validate` to check syntax
- Run `terraform plan` to preview changes
- Review plan output for unintended changes or deletions
- Check for security issues (open security groups, public access, etc.)

### Post-Apply Validation
- Verify resources were created as expected
- Test connectivity and functionality
- Validate security configurations
- Check cost implications
- Document any manual steps required

## Common Patterns

### Multi-Environment Setup
```hcl
# Use workspaces or separate state files
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "env/${terraform.workspace}/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Module Composition
```hcl
module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  cidr_block  = var.vpc_cidr

  tags = local.common_tags
}

module "app" {
  source = "./modules/app"

  vpc_id    = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  depends_on = [module.vpc]
}
```

### Conditional Resources
```hcl
resource "aws_cloudwatch_alarm" "high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  # ...
}
```

## Troubleshooting

### Common Issues
1. **State Lock Conflicts**: Use force-unlock only when safe
2. **Provider Authentication**: Ensure credentials are properly configured
3. **Resource Dependencies**: Use depends_on when implicit dependencies aren't detected
4. **Import Existing Resources**: Use `terraform import` for brownfield infrastructure
5. **Drift Detection**: Regular `terraform plan` to detect configuration drift

### When to Escalate
- Destructive changes detected unexpectedly
- State file corruption or conflicts
- Provider API errors or rate limiting
- Complex dependency issues
- Security concerns or compliance violations
- **Any request to use lifecycle.ignore_changes**

## References
- Terraform Documentation: https://www.terraform.io/docs
- AWS Provider: https://registry.terraform.io/providers/hashicorp/aws
- Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm
- GCP Provider: https://registry.terraform.io/providers/hashicorp/google
