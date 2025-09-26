# Gaming PC Security Implementation Guide

## 🎮 Secure Gaming Infrastructure Implementation

This guide provides step-by-step instructions to implement secure gaming infrastructure for your family gaming PC, addressing the multi-user access challenge without compromising security.

## Current Architecture Analysis

### ✅ Proper Workspace Usage
**Use the `compute` workspace** as your primary gaming infrastructure:
- Already has proper multi-workspace integration
- Supports multiple EC2 instances
- Has EIP assignments for consistent access
- Includes comprehensive security group architecture

### ❌ Deprecated Workspace
**Avoid the `terraform-test` workspace**:
- Duplicates functionality from `compute`
- Has configuration errors and missing dependencies
- Creates conflicting infrastructure

## Security Implementation Steps

### Phase 1: Apply Gaming Optimizations to Compute Workspace

1. **Update Instance Configuration** in `compute/main.tf`:
```hcl
# Replace existing instance configuration
resource "aws_instance" "my_tf_ec2" {
  count         = var.ec2_instance_count
  ami           = local.gaming_ami.windows_server_2022  # Gaming-optimized Windows AMI
  instance_type = local.gaming_instance_types.budget   # GPU instance for gaming
  subnet_id     = data.terraform_remote_state.vpc.outputs.subnet_id_list[count.index]
  user_data     = local.windows_gaming_userdata        # Gaming setup script
  security_groups = [
    aws_security_group.gaming_pc_secure_sg.id,         # VPN-only access
    aws_security_group.allow_ips_for_packages_sg.id
  ]
  key_name = "cloud_gaming"
  
  # Enable detailed monitoring for gaming performance
  monitoring = true
  
  # Optimize EBS for gaming performance
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 100
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
    encrypted             = true
  }
  
  timeouts {
    create = "15m"  # Gaming instances take longer to configure
  }

  tags = merge(local.common_tags, {
    "Name" = "Gaming-PC-${count.index}",
    "TYPE" = "gaming-instance",
    "OS"   = "windows"
  })
}
```

2. **Add Gaming Variables** to `compute/variables.tf`:
```hcl
variable "windows_admin_password" {
  description = "Administrator password for Windows gaming instances"
  type        = string
  sensitive   = true
  
  validation {
    condition = can(regex("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{12,}$", var.windows_admin_password))
    error_message = "Password must be at least 12 characters with mixed case, numbers, and special characters."
  }
}

variable "gaming_performance_tier" {
  description = "Gaming performance tier: budget, performance, or premium"
  type        = string
  default     = "budget"
}

variable "enable_gaming_optimizations" {
  description = "Enable gaming-specific optimizations"
  type        = bool
  default     = true
}
```

### Phase 2: Implement VPN-Based Security

#### Option A: AWS Client VPN (Recommended for Families)

1. **Generate VPN Certificates**:
```bash
# Run these commands to generate certificates
mkdir -p compute/certs
cd compute/certs

# Generate CA private key
openssl genrsa -out ca.key 2048

# Generate CA certificate
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=US/ST=State/L=City/O=GamingVPN/CN=GamingCA"

# Generate server private key
openssl genrsa -out server.key 2048

# Generate server certificate signing request
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=State/L=City/O=GamingVPN/CN=server"

# Sign server certificate
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

# Generate client private key
openssl genrsa -out client.key 2048

# Generate client certificate signing request
openssl req -new -key client.key -out client.csr -subj "/C=US/ST=State/L=City/O=GamingVPN/CN=client"

# Sign client certificate
openssl x509 -req -days 3650 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt
```

2. **Apply VPN Configuration** (from `gaming-security-improvements.tf`):
```bash
cd compute/
cp ../terraform-test/gaming-security-improvements.tf ./gaming-security.tf
terraform plan -var="windows_admin_password=YourSecurePassword123!"
terraform apply
```

#### Option B: Simple VPN Server (Alternative)

If AWS Client VPN is too complex, deploy OpenVPN server:

```hcl
# Add to compute/main.tf
resource "aws_instance" "vpn_server" {
  ami           = "ami-0c02fb55956c7d316"  # Amazon Linux
  instance_type = "t3.micro"
  subnet_id     = data.terraform_remote_state.vpc.outputs.subnet_id_list[0]
  
  user_data = base64encode(templatefile("${path.module}/user_data/openvpn-setup.sh", {
    gaming_subnet = "15.0.0.0/16"
  }))
  
  security_groups = [aws_security_group.vpn_server_sg.id]
  
  tags = {
    Name = "Gaming-VPN-Server"
  }
}

resource "aws_security_group" "vpn_server_sg" {
  name_prefix = "vpn-server-"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  
  # OpenVPN port
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # SSH for management
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_MANAGEMENT_IP/32"]  # Replace with your IP
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Phase 3: Gaming-Specific Security

1. **Replace Existing Security Groups** in `compute/main.tf`:
```hcl
# Remove wide-open security groups, replace with:
resource "aws_security_group" "gaming_secure_sg" {
  name        = "gaming-secure-access"
  description = "Secure gaming access"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # RDP for Windows gaming - VPN only
  ingress {
    description = "RDP via VPN"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.vpn_client_cidr]  # Only VPN clients
  }

  # Steam gaming ports - VPN only
  ingress {
    description = "Steam gaming"
    from_port   = 27015
    to_port     = 27030
    protocol    = "tcp"
    cidr_blocks = [var.vpn_client_cidr]
  }

  # No SSH - use RDP for Windows
  # Remove all SSH ingress rules

  tags = local.common_tags
}
```

### Phase 4: Family Access Management

#### User Management Strategy

1. **VPN Certificate Distribution**:
```bash
# Create certificates for each family member
family_members=("brother1" "brother2" "brother3")

for member in "${family_members[@]}"; do
    # Generate individual client certificates
    openssl genrsa -out "client-${member}.key" 2048
    openssl req -new -key "client-${member}.key" -out "client-${member}.csr" -subj "/CN=${member}"
    openssl x509 -req -days 365 -in "client-${member}.csr" -CA ca.crt -CAkey ca.key -CAcreateserial -out "client-${member}.crt"
    
    # Create VPN profile
    cat > "${member}-gaming-vpn.ovpn" << EOF
client
dev tun
proto udp
remote ${VPN_ENDPOINT} 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client-${member}.crt
key client-${member}.key
verb 3
EOF
done
```

2. **Gaming Session Scheduling**:
```hcl
# Add to compute/main.tf for automated scheduling
resource "aws_lambda_function" "gaming_scheduler" {
  filename      = "gaming-scheduler.zip"
  function_name = "gaming-session-scheduler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"

  environment {
    variables = {
      GAMING_INSTANCE_IDS = join(",", aws_instance.my_tf_ec2[*].id)
    }
  }
}

# CloudWatch Events for scheduling
resource "aws_cloudwatch_event_rule" "gaming_schedule" {
  name                = "gaming-schedule"
  description         = "Start/stop gaming instances on schedule"
  schedule_expression = "cron(0 18 * * ? *)"  # 6 PM daily
}
```

## Family Gaming Access Workflow

### For Family Members:

1. **Install VPN Client**:
   - Download OpenVPN client
   - Import their personal `.ovpn` profile
   - Connect to gaming VPN

2. **Access Gaming PC**:
   - Connect to VPN first
   - Use Remote Desktop to connect to gaming PC private IP
   - Log in with their gaming account

3. **Gaming Session**:
   - Launch Steam/Epic Games/etc.
   - Play games with full performance
   - Disconnect RDP when done (keeps games running)

### For Administrator:

1. **Monitor Usage**:
```bash
# Check VPN connections
aws ec2 describe-client-vpn-connections --client-vpn-endpoint-id ${VPN_ENDPOINT_ID}

# Check gaming instance status  
aws ec2 describe-instances --instance-ids ${GAMING_INSTANCE_IDS}
```

2. **Manage Access**:
```bash
# Revoke certificate if needed
aws ec2 revoke-client-vpn-ingress --client-vpn-endpoint-id ${VPN_ENDPOINT_ID}

# Add new family member
# Generate new certificate and update VPN authorization rules
```

## Cost Optimization

### Gaming Instance Scheduling
```hcl
# Auto-shutdown during off-hours
resource "aws_instance_schedule" "gaming_hours" {
  name     = "gaming-schedule"  
  schedule = "0 8 * * 1-5"      # Weekdays 8 AM
  timezone = "America/New_York"
  
  instances = aws_instance.my_tf_ec2[*].id
  
  # Stop instances at midnight
  shutdown_schedule = "0 0 * * *"
}
```

## Security Monitoring

### CloudWatch Alarms
```hcl
resource "aws_cloudwatch_metric_alarm" "gaming_cpu_high" {
  alarm_name          = "gaming-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Gaming instance high CPU usage"
  
  dimensions = {
    InstanceId = aws_instance.my_tf_ec2[0].id
  }
}
```

## Deployment Commands

```bash
# 1. Apply VPC first
cd vpc/
terraform init && terraform apply

# 2. Apply gaming compute infrastructure  
cd ../compute/
terraform init
terraform apply -var="windows_admin_password=YourSecurePassword123!"

# 3. Apply DNS infrastructure
cd ../zone-infrastructure/
terraform init && terraform apply

# 4. Configure VPN access
# Generate certificates (as shown above)
# Distribute .ovpn files to family members
```

## Security Checklist

- [ ] Replace Linux AMI with Windows Server for gaming
- [ ] Upgrade to GPU instance type (g4dn.xlarge minimum)
- [ ] Remove SSH access, use RDP only
- [ ] Implement VPN-only access (no direct internet)
- [ ] Generate unique VPN certificates for each family member
- [ ] Enable encryption for EBS volumes
- [ ] Set up CloudWatch monitoring and alerts
- [ ] Configure automatic security updates
- [ ] Implement gaming session scheduling
- [ ] Document access procedures for family members

This implementation provides secure, scalable gaming infrastructure that allows family access without compromising security.