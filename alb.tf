
resource "aws_alb" "ec2_deployer_alb" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  #  security_groups    = [aws_security_group.lb_sg.id]
  #  subnets            = [for subnet in aws_subnet.public : subnet.id]
#  subnets            = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
#  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]
  #  subnets            = [aws_subnet.public_subnet.id]
  security_groups = [aws_security_group.ec2_deployer_alb_sg.id, aws_security_group.sg.id]
#  access_logs {
#    bucket = "vpc-flow-logs123"
#    enabled = true
#  }
  subnet_mapping {
    subnet_id = aws_subnet.public_subnet.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.public_subnet_2.id
  }
#  depends_on = [aws_subnet.public_subnet]
  tags = local.alb_tags
}

resource "aws_security_group" "ec2_deployer_alb_sg" {
  name = "allow_http_from_internet"
  description = "Allow HTTP from internet"
  vpc_id = aws_vpc.ec2_deployer_vpc.id
  ingress {
    description = "Allow HTTP from Internet to ALB"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow ALB from Internet to HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS from Internet to ALB"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    #    cidr_blocks = [aws_security_group.ec2_deployer_alb_sg.id]
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    description = "Allow ALB from Internet to HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    #    cidr_blocks = [aws_security_group.ec2_deployer_alb_sg.id]
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.common_tags
}

resource "aws_alb_target_group" "ec2_target_group" {
  name = "ec2-target-group"
  port = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = aws_vpc.ec2_deployer_vpc.id
  #  tags = local.common_tags
}

resource "aws_alb_target_group_attachment" "ec2_target_group_attachment"{
  target_group_arn = aws_alb_target_group.ec2_target_group.arn
  target_id = aws_instance.my_tf_ec2.id
  port = 80
}

resource "aws_alb_listener" "alb_listener"{
  load_balancer_arn = aws_alb.ec2_deployer_alb.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.ec2_target_group.arn
  }
}

resource "aws_alb_listener_rule" "alb_listener_rule"{
  listener_arn = aws_alb_listener.alb_listener.arn
  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.ec2_target_group.arn
  }
#  condition {
#    host_header {
#      values = ["*ec2deployer.com"]
#    }
#  }
  condition {
    path_pattern {
#      values = ["/var/www/html/index.html"]
      values = ["/"]
    }
  }
}