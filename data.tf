#data "aws_ami" "ubuntu" {
#  most_recent = true
#  owners = ["amazon"]
#}


data "aws_ssm_parameter" "main_zone_id" {
  name = "/application/ec2deployer/resource/main/zone-id"
}

data "aws_route53_zone" "main_zone" {
  zone_id = data.aws_ssm_parameter.main_zone_id.value

}

data "aws_iam_role" "cloudwatchlogger" {
  name = "cloudwatch-logger"
}