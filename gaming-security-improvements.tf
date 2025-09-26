# Gaming PC Security Improvements for Compute Workspace
# Apply these changes to the compute workspace for secure gaming infrastructure

# 1. GAMING-OPTIMIZED INSTANCE TYPES
# Replace in compute/locals.tf or variables
locals {
  # Gaming instance types with GPU support
  gaming_instance_types = {
    budget = "g4dn.xlarge"      # 4 vCPU, 16GB RAM, T4 GPU - Good for most games
    performance = "g4dn.2xlarge" # 8 vCPU, 32GB RAM, T4 GPU - High performance
    premium = "g5.2xlarge"       # 8 vCPU, 32GB RAM, A10G GPU - Latest games
  }
  
  # Windows gaming AMI (replace ami-005f9685cb30f234b in compute/main.tf)
  gaming_ami = {
    windows_server_2022 = "ami-0c02fb55956c7d316"  # Windows Server 2022
    windows_server_2019 = "ami-0b69ea66ff7391e80"  # Windows Server 2019
  }
  
  instance_type = var.gaming_performance_tier == "budget" ? local.gaming_instance_types.budget : 
                  var.gaming_performance_tier == "performance" ? local.gaming_instance_types.performance : 
                  local.gaming_instance_types.premium
}

# 2. VPN-BASED SECURITY ARCHITECTURE
# Replace wide-open security groups with VPN-only access

# VPN Client Endpoint for secure gaming access
resource "aws_ec2_client_vpn_endpoint" "gaming_vpn" {
  description            = "Gaming PC VPN Access"
  client_cidr_block      = "10.10.0.0/16"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  
  authentication_options {
    type               = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_client.arn
  }
  
  connection_log_options {
    enabled = true
    cloudwatch_log_group = aws_cloudwatch_log_group.vpn_logs.name
  }
  
  tags = merge(local.common_tags, {
    Name = "Gaming-VPN"
  })
}

# VPN Network Association
resource "aws_ec2_client_vpn_network_association" "gaming_vpn_association" {
  count                  = length(data.terraform_remote_state.vpc.outputs.subnet_id_list)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.gaming_vpn.id
  subnet_id              = data.terraform_remote_state.vpc.outputs.subnet_id_list[count.index]
}

# VPN Authorization Rule
resource "aws_ec2_client_vpn_authorization_rule" "gaming_vpn_auth" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.gaming_vpn.id
  target_network_cidr    = "15.0.0.0/16"  # VPC CIDR from vpc workspace
  authorize_all_groups   = true
}

# 3. SECURE GAMING SECURITY GROUPS
# Replace existing security groups with VPN-only access

resource "aws_security_group" "gaming_pc_secure_sg" {
  name        = "gaming-pc-secure-access"
  description = "Secure gaming PC access via VPN only"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # Remote Desktop Protocol (RDP) for Windows gaming - VPN only
  ingress {
    description = "RDP access via VPN"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]  # VPN client CIDR
  }

  # Steam gaming ports - VPN only
  ingress {
    description = "Steam gaming ports via VPN"
    from_port   = 27015
    to_port     = 27030
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }
  
  ingress {
    description = "Steam gaming ports UDP via VPN"
    from_port   = 27015
    to_port     = 27030
    protocol    = "udp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  # Discord voice chat - VPN only
  ingress {
    description = "Discord voice chat via VPN"
    from_port   = 50000
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  # HTTP/HTTPS for game downloads - VPN only
  ingress {
    description = "HTTP via VPN"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    description = "HTTPS via VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  # Outbound internet access for game downloads and updates
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "Gaming-PC-Secure-SG"
  })
}

# 4. ALB SECURITY GROUP - GAMING WEB INTERFACE
# For game server management interfaces accessible via ALB

resource "aws_security_group" "gaming_alb_secure_sg" {
  name        = "gaming-alb-secure"
  description = "Secure ALB for gaming management interfaces"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # HTTPS only for gaming management interfaces
  ingress {
    description = "HTTPS for gaming management"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.trusted_management_cidrs  # Define trusted IP ranges
  }

  # Outbound to gaming instances
  egress {
    description     = "HTTPS to gaming instances"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.gaming_pc_secure_sg.id]
  }

  tags = merge(local.common_tags, {
    Name = "Gaming-ALB-Secure-SG"
  })
}

# 5. SSL CERTIFICATE FOR HTTPS
resource "aws_acm_certificate" "gaming_cert" {
  domain_name       = var.gaming_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.gaming_domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "Gaming-SSL-Certificate"
  })
}

# 6. VPN CERTIFICATES
resource "aws_acm_certificate" "vpn_server" {
  private_key      = file("${path.module}/certs/server.key")
  certificate_body = file("${path.module}/certs/server.crt")
  
  tags = merge(local.common_tags, {
    Name = "Gaming-VPN-Server-Cert"
  })
}

resource "aws_acm_certificate" "vpn_client" {
  private_key      = file("${path.module}/certs/client.key")
  certificate_body = file("${path.module}/certs/client.crt")
  
  tags = merge(local.common_tags, {
    Name = "Gaming-VPN-Client-Cert"
  })
}

# 7. CLOUDWATCH LOGGING FOR SECURITY MONITORING
resource "aws_cloudwatch_log_group" "vpn_logs" {
  name              = "/aws/vpn/gaming-access"
  retention_in_days = 30
  
  tags = merge(local.common_tags, {
    Name = "Gaming-VPN-Logs"
  })
}

resource "aws_cloudwatch_log_group" "gaming_security_logs" {
  name              = "/aws/gaming/security-events"
  retention_in_days = 90
  
  tags = merge(local.common_tags, {
    Name = "Gaming-Security-Logs"
  })
}

# 8. VARIABLES TO ADD TO compute/variables.tf
# Add these variables to compute workspace

variable "gaming_performance_tier" {
  description = "Gaming performance tier: budget, performance, or premium"
  type        = string
  default     = "budget"
  
  validation {
    condition = contains(["budget", "performance", "premium"], var.gaming_performance_tier)
    error_message = "Gaming performance tier must be budget, performance, or premium."
  }
}

variable "gaming_domain" {
  description = "Domain name for gaming infrastructure"
  type        = string
  default     = "gaming.ec2deployer.com"
}

variable "trusted_management_cidrs" {
  description = "Trusted CIDR blocks for gaming management access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # CHANGE THIS - Add your trusted IPs
}

variable "enable_vpn_access" {
  description = "Enable VPN-based access instead of direct internet access"
  type        = bool
  default     = true
}

# 9. GAMING PC USER DATA FOR WINDOWS
# Replace user_data/userdata.ssh with Windows gaming setup
locals {
  windows_gaming_userdata = base64encode(templatefile("${path.module}/user_data/windows-gaming-setup.ps1", {
    admin_password = var.windows_admin_password
  }))
}