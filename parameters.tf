# --------------------------- SSM PARAMETERS ---------------------------

resource "aws_ssm_parameter" "dev_zone_id_ssm" {
  type = "String"
  name = "/application/ec2deployer/resource/terraform/zone-id"
  value = aws_route53_zone.dev_zone.zone_id
  tags = local.common_tags
}

resource "aws_ssm_parameter" "public_subnet_id" {
  type = "String"
  name = "/application/ec2deployer/resource/terraform/public-subnet-id"
  value = aws_subnet.public_subnet.id
  tags = local.common_tags
}

#resource "aws_ssm_parameter" "private_subnet_id" {
#  type = "String"
#  name = "/application/ec2deployer/resource/terraform/private-subnet-id"
#  value = aws_subnet.private_subnet.id
#  tags = local.common_tags
#}

resource "aws_ssm_parameter" "vpc_id" {
  type = "String"
  name = "/application/ec2deployer/resource/terraform/vpc-id"
  value = aws_vpc.ec2_deployer_vpc.id
  tags = local.common_tags
}

resource "aws_ssm_parameter" "cloudwatch_log_group" {
  type = "String"
  name = "/application/ec2deployer/resource/terraform/vpc-cloudwatch-log-group"
  value = aws_cloudwatch_log_group.ec2deployer_log_group.name
  tags = local.common_tags
}