
output "vpc_id" {
  value = aws_vpc.ec2_deployer_vpc.id
}

output "alb_arn" {
  value = aws_alb.ec2_deployer_alb.arn
}

output "alb_dns_name" {
  value = aws_alb.ec2_deployer_alb.dns_name
}

output "alb_hosted_zone_id" {
  value = aws_alb.ec2_deployer_alb.zone_id
}


#output "dev_records_to_main_zone_zone_id" {
#  value = nonsensitive(aws_route53_record.dev_records_to_main_zone.zone_id)
#}

output "main_zone_id" {
  value = nonsensitive(data.aws_route53_zone.main_zone.zone_id)

}

#output "dev_zone_id" {
#  value = aws_route53_zone.dev_zone.zone_id
#}

#output "dev_zone_ns" {
#  value = aws_route53_zone.dev_zone.name_servers
#}

output "vpc-cloudwatch-log-group" {
  value = aws_cloudwatch_log_group.ec2deployer_log_group.name
}

output "outpost_id" {
  value = aws_alb.ec2_deployer_alb.subnet_mapping.*.outpost_id
}