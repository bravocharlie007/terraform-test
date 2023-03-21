resource "aws_vpc" "ec2_deployer_vpc" {
  cidr_block = local.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = local.vpc_tags
}

resource "aws_cloudwatch_log_group" "ec2deployer_log_group" {
  name = "ec2deployer-VPC-logs-group"
  retention_in_days = 30
}

resource "aws_flow_log" "ec2deployer_vpc_flow_log" {
  traffic_type = "ALL"
  iam_role_arn = data.aws_iam_role.cloudwatchlogger.arn
  log_destination_type = "cloud-watch-logs"
  log_destination = aws_cloudwatch_log_group.ec2deployer_log_group.arn
  vpc_id = aws_vpc.ec2_deployer_vpc.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.ec2_deployer_vpc.id
  cidr_block = local.public_subnet_cidr
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = local.public_subnet_tags
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.ec2_deployer_vpc.id
  cidr_block = "10.0.4.0/27"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = local.public_subnet_tags
}

#resource "aws_subnet" "private_subnet" {
#  vpc_id = aws_vpc.ec2_deployer_vpc.id
#  cidr_block = local.private_subnet_cidr
#  availability_zone = "us-east-1b"
#  map_public_ip_on_launch = false
#  tags = local.private_subnet_tags
#}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ec2_deployer_vpc.id
  tags = local.igw_tags
}


#resource "aws_route53_zone" dev_zone {
#  name = local.zone_name
#  tags_all = local.zone_tags
#}

resource "aws_route53_record" "alias_alb_record" {
  zone_id = data.terraform_remote_state.zone.outputs.zone_id
  name = "dev.${var.domain}"
  type = "A"

  alias {
    name = aws_alb.ec2_deployer_alb.dns_name
    zone_id = aws_alb.ec2_deployer_alb.zone_id
    evaluate_target_health = true
  }
}

#resource "aws_route53_record" "alias_alb_record_2" {
#  zone_id = aws_route53_zone.dev_zone.zone_id
#  name = local.zone_name
#  type = "A"
#
#  alias {
#    name = aws_alb.ec2_deployer_alb.dns_name
#    zone_id = aws_alb.ec2_deployer_alb.zone_id
#    evaluate_target_health = false
#  }
#}

resource "aws_route53_record" "alias_alb_record_in_main_zone" {
  zone_id = data.aws_route53_zone.main_zone.id
  name =  "temporary.${local.project_name}.com"
  type = "A"

  alias {
    name = aws_alb.ec2_deployer_alb.dns_name
    zone_id = aws_alb.ec2_deployer_alb.zone_id
    evaluate_target_health = true
  }
}



#resource "aws_route53_record" "add_dev_records_to_main_zone" {
#  name = "dev.ec2deployer.com"
#  type = "NS"
##  type = "A"
#  ttl  = "3000"
#  zone_id = data.aws_ssm_parameter.main_zone_id.value
#  records = aws_route53_zone.dev_zone.name_servers
##  records = [aws_alb.ec2_deployer_alb.dns_name]
#
#}

resource "aws_route_table" ec2_deployer_vpc_route_table {
  vpc_id = aws_vpc.ec2_deployer_vpc.id
  tags = {
    "Name" = "PublicRouteTable-${var.environment}"
  }
}

resource "aws_route" "route_to_igw" {
  route_table_id = aws_route_table.ec2_deployer_vpc_route_table.id
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_subnet_to_route_table" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.ec2_deployer_vpc_route_table.id
}

resource "aws_route_table_association" "public_subnet_to_route_table_2" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.ec2_deployer_vpc_route_table.id
}

#resource "aws_route_table_association" "private_subnet_to_route_table" {
#  subnet_id = aws_subnet.private_subnet.id
#  route_table_id = aws_route_table.ec2_deployer_vpc_route_table.id
#}

#
#resource "aws_network_acl" "main"{
#  vpc_id = aws_vpc.ec2_deployer_vpc.id
#  egress {
#    protocol = "tcp"
#    rule_no = 200
#    action = "allow"
#    cidr_block = "0.0.0.0/0"
#    from_port = 80
#    to_port = 80
#  }
#  ingress {
#    protocol = "tcp"
#    rule_no = 100
#    action = "allow"
#    cidr_block = "0.0.0.0/0"
#    from_port = 80
#    to_port = 80
#  }
#  tags = local.common_tags
#}

# --------------------------- NOT NEEDED ---------------------------
# Creates a record in the Main Zone linking to the name servers of ${ENV} Zone
#resource "aws_route53_record" "dev_records_to_main_zone" {
#  name = "temp2.ec2deployer.com"
#  type = "NS"
#  ttl  = "3000"
#  zone_id = data.aws_ssm_parameter.main_zone_id.value
#  records = aws_route53_zone.dev_zone.name_servers
#}

#resource "aws_security_group_rule" "alb_to_ec2_sg_rule"{
#  type = "ingress"
#  from_port = 80
#  to_port = 80
#  protocol = "tcp"
#
#}

