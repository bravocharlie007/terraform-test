# EC2 Deployer Infrastructure

## Overview
This Terraform configuration creates a complete AWS infrastructure for deploying a web application on EC2 instances with high availability through an Application Load Balancer (ALB). The infrastructure supports multiple environments (dev/prod) and includes comprehensive logging and monitoring capabilities.

## Architecture

### High-Level Architecture
```
Internet → Application Load Balancer → EC2 Instance (Web Server)
           ↓
    Route53 DNS Records ← VPC with Public Subnets
           ↓
    CloudWatch Logging ← VPC Flow Logs
```

### Components

#### Core Infrastructure (main.tf)
- **VPC**: Custom VPC with CIDR `10.0.0.0/16`
- **Public Subnets**: Two public subnets in different AZs (`us-east-1a`, `us-east-1b`)
  - Subnet 1: `10.0.0.0/27` 
  - Subnet 2: `10.0.4.0/27`
- **Internet Gateway**: Provides internet access to public subnets
- **Route Tables**: Custom routing configuration for internet access
- **VPC Flow Logs**: Comprehensive network traffic logging to CloudWatch

#### Compute (ec2.tf)
- **EC2 Instance**: Single `t3.micro` instance running Amazon Linux
- **Auto-configuration**: Apache web server installation via user data
- **Security Groups**: Controlled access for HTTP/HTTPS traffic from ALB
- **AMI**: `ami-0557a15b87f6559cf` (Amazon Linux)

#### Load Balancing (alb.tf)
- **Application Load Balancer**: Public-facing ALB across multiple AZs
- **Target Group**: HTTP target group for EC2 instance health checks
- **Security Groups**: Internet-facing security groups for HTTP/HTTPS
- **Listener Rules**: Traffic routing based on path patterns

#### DNS & Networking (main.tf, data.tf)
- **Route53 Records**: DNS aliases pointing to ALB
  - Development subdomain: `dev.{domain}`
  - Temporary domain: `temporary.ec2deployer.com`
- **External Dependencies**: References to external Route53 zones via remote state

#### Security (security_group.tf)
- **Dynamic Security Groups**: Configurable ingress rules for HTTP, HTTPS, SSH
- **Least Privilege**: Targeted security group rules between components
- **Internet Access**: Controlled egress rules for necessary outbound traffic

#### Monitoring & Logging
- **CloudWatch Log Groups**: 30-day retention for VPC flow logs
- **IAM Integration**: CloudWatch logger role for flow log permissions
- **SSM Parameters**: Infrastructure resource IDs stored for cross-workspace sharing

## Configuration

### Required Variables
- `org_name`: Terraform Cloud organization name
- `zone_workspace_name`: Workspace containing Route53 zone configuration
- `domain`: Primary domain for DNS records
- `environment`: Deployment environment (default: "dev")

### Optional Variables
- `aws_access_key_id`: AWS access key (empty by default, uses IAM roles)
- `aws_secret_access_key`: AWS secret key (empty by default)
- `aws_account_id`: Target AWS account (default: "191805346255")
- `region`: AWS region (default: "us-east-1")
- `sso_profile`: AWS SSO profile name (default: "CharlesIC")
- `assume_role`: IAM role for Terraform operations (default: "tf-pave-apply")

### Resource Naming Convention
Resources follow the pattern: `{project_name}-{component}-{environment}`
- Project name: `ec2deployer`
- Components: `vpc`, `alb`, `subnet`, etc.
- Tags include: PROJECT_NAME, PROJECT_COMPONENT, ENVIRONMENT, DEPLOYMENT_ID

## Workspace Dependencies

### External Dependencies
1. **Zone Workspace**: Contains Route53 hosted zone configuration
   - Expected output: `zone_id`
   - Referenced in: `data.terraform_remote_state.zone`

2. **SSM Parameters**: Main zone configuration stored in Parameter Store
   - Parameter: `/application/ec2deployer/resource/main/{environment}/zone-id`
   - Used for cross-environment DNS management

### Outputs Available for Other Workspaces
- `vpc_id`: VPC identifier for network sharing
- `alb_arn`: Load balancer ARN for reference
- `alb_dns_name`: Load balancer DNS name
- `alb_hosted_zone_id`: ALB's Route53 zone ID
- `main_zone_id`: Route53 zone identifier
- `vpc-cloudwatch-log-group`: CloudWatch log group name

## Security Considerations & Concerns

### ⚠️ Security Issues Identified

#### High Priority
1. **Hardcoded AWS Account ID**: Account ID `191805346255` is exposed in `variables.tf`
2. **Wide-Open Security Groups**: Security groups allow `0.0.0.0/0` access on multiple ports
3. **SSH Access**: SSH (port 22) is open to the internet with password authentication enabled
4. **Unencrypted User Data**: Sensitive configuration in plain text user data scripts

#### Medium Priority
1. **No HTTPS Termination**: ALB listener only configured for HTTP (port 80)
2. **Single EC2 Instance**: No high availability or auto-scaling configured
3. **Deprecated AWS Provider**: Using AWS provider v4.0.0 (released 2022)
4. **Missing Backup Strategy**: No automated backups for EC2 instances

#### Configuration Issues
1. **Incomplete Remote State**: Missing `backend` configuration in `data.tf`
2. **Referenced Missing Resources**: `aws_route53_zone.dev_zone` referenced but not defined
3. **Commented Critical Code**: Route53 zone creation is commented out
4. **Mixed Resource Types**: Uses deprecated `aws_alb` instead of `aws_lb`

### Recommended Security Improvements
1. Use AWS Systems Manager Session Manager instead of SSH
2. Implement least-privilege security groups
3. Add SSL/TLS certificates for HTTPS
4. Enable encryption at rest and in transit
5. Use AWS Secrets Manager for sensitive data
6. Implement AWS Config for compliance monitoring
7. Add VPC endpoints to reduce internet traffic

## Usage

### Prerequisites
- Terraform v1.4.0
- AWS CLI configured with appropriate permissions
- Route53 hosted zone pre-configured in separate workspace

### Deployment
```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan -var="org_name=your-org" -var="domain=your-domain.com"

# Apply configuration
terraform apply
```

### User Data Scripts
Two user data scripts are available:
- `user_data/userdata.ssh`: Full Apache setup with SSH configuration
- `user_data/my_userdata.ssh`: Basic Apache setup

## Infrastructure Outputs
After deployment, the following endpoints will be available:
- Web application: `http://dev.{your-domain}`
- Temporary endpoint: `http://temporary.ec2deployer.com`
- Direct ALB access: `{alb-dns-name}.us-east-1.elb.amazonaws.com`

## Development Notes
- Original development appears to be over 2 years old
- Configuration shows multi-environment intentions (dev/prod)
- Some resources are commented out, suggesting incomplete implementation
- Evidence of iterative development with multiple approaches tried

## Next Steps
1. Fix configuration validation errors
2. Implement proper HTTPS with SSL certificates
3. Add auto-scaling group for high availability
4. Implement proper secrets management
5. Update to latest Terraform AWS provider
6. Add comprehensive monitoring and alerting