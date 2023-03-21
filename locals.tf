resource "random_id" "deployment_id" {
  byte_length = 6
}

# Have 3 accounts
# One deployer account, one dev account, one dev account
# have terraform code to do: if env=prod select prod environment
locals {
  subnets                = ["PublicSubnet01", "PublicSubnet02"]
  project_name           = "ec2deployer"
  replace_string         = "REPLACEME"
  localized_project_name = "${local.project_name}-${local.replace_string}-${local.upper_env}"
  project_component      = "network-infrastructure"
  upper_env              = upper(var.environment)
  alb_name               = replace(local.localized_project_name, local.replace_string, local.alb_type)
  zone_name              = var.domain
  base_vpc_ip            = "10.0.0.0"
  base_private_subnet_ip = "10.0.1.0"
  vpc_mask               = 16
  subnet_mask            = 27
  vpc_cidr               = "${local.base_vpc_ip}/${local.vpc_mask}"
  private_subnet_cidr    = "${local.base_private_subnet_ip}/${local.subnet_mask}"
  public_subnet_cidr     = "${local.base_vpc_ip}/${local.subnet_mask}"
  timestamp              = timestamp()
  vpc_type               = "vpc"
  subnet_type            = "subnet"
  alb_type               = "alb"
  igw_type               = "igw"
  nacl_type              = "nacl"
  zone_type              = "zone"
  record_type            = "record"
  route_table_type       = "route-table"
  public_subnet_type     = "public"
  private_subnet_type    = "private"
  instance_type          = "t3.micro"
  ami_id                 = "ami-0557a15b87f6559cf"
  common_tags            = tomap({
    "PROJECT_NAME"      = local.project_name,
    "PROJECT_COMPONENT" = local.project_component,
    "ENVIRONMENT"       = local.upper_env,
    "DEPLOYMENT_ID"     = random_id.deployment_id.hex
#    "TIMESTAMP"         = local.timestamp
  })
  vpc_tags = merge(
    tomap({
      "Name" = replace(local.localized_project_name, local.replace_string, local.vpc_type),
      "NAME" = replace(local.localized_project_name, local.replace_string, local.vpc_type),
      "TYPE" = local.vpc_type
    }),
    local.common_tags
  )
  public_subnet_tags = merge(
    tomap({
      "Name" = replace(local.localized_project_name, local.replace_string, "${local.public_subnet_type}-${local.subnet_type}"),
      "NAME"        = replace(local.localized_project_name, local.replace_string, "${local.public_subnet_type}-${local.subnet_type}"),
      "TYPE"        = local.subnet_type,
      "SUBNET_TYPE" = local.public_subnet_type
    }),
    local.common_tags
  )
  private_subnet_tags = merge(
    tomap({
      "Name" = replace(local.localized_project_name, local.replace_string, "${local.private_subnet_type}-${local.subnet_type}"),
      "NAME"        = replace(local.localized_project_name, local.replace_string, "${local.private_subnet_type}-${local.subnet_type}"),
      "TYPE"        = local.subnet_type,
      "SUBNET_TYPE" = local.private_subnet_type
    }),
    local.common_tags
  )
  alb_tags = merge(
    tomap({
      "Name" = replace(local.localized_project_name, local.replace_string, local.alb_type),
      "NAME" = local.alb_name
      "TYPE" = local.alb_type
    }),
    local.common_tags
  )
  igw_tags = merge(
    tomap({
      "Name" = replace(local.localized_project_name, local.replace_string, local.zone_type),
      "NAME" = replace(local.localized_project_name, local.replace_string, local.igw_type),
      "TYPE" = local.igw_type
    }),
    local.common_tags
  )
  zone_tags = merge(
    tomap({
      "Name" = replace(local.localized_project_name, local.replace_string, local.zone_type),
      "NAME" = replace(local.localized_project_name, local.replace_string, local.zone_type),
      "TYPE" = local.zone_type
    }),
    local.common_tags
  )
}


locals {
  ingress_rules = [{
    name        = "HTTPS"
    port        = 443
    description = "Ingress rules for port 443"
  },
    {
      name        = "HTTP"
      port        = 80
      description = "Ingress rules for port 80"
    },
    {
      name        = "SSH"
      port        = 22
      description = "Ingress rules for port 22"
    }]

}

