resource "aws_instance" "my_tf_ec2" {
  ami = local.ami_id
  instance_type = local.instance_type
  subnet_id = aws_subnet.public_subnet.id
  user_data = file("${path.module}/user_data/userdata.ssh")
  security_groups = [aws_security_group.my_tf_ec2_sg.id, aws_security_group.sg.id,]
  #  tags = local.common_tags
}

resource "aws_security_group" "my_tf_ec2_sg" {
  name = "allow_http_from_alb_sg_to_ec2"
  description = "Allow HTTP from ALB SG"
  vpc_id = aws_vpc.ec2_deployer_vpc.id
  ingress {
    description = "Allow HTTP from ALB security group to instance"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    #    cidr_blocks = [aws_security_group.ec2_deployer_alb_sg.id]
    security_groups = [aws_security_group.ec2_deployer_alb_sg.id]

  }
  egress {
    description = "Allow HTTP from instance to ALB SG"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    #    cidr_blocks = [aws_security_group.ec2_deployer_alb_sg.id]
    security_groups = [aws_security_group.ec2_deployer_alb_sg.id]
  }
  ingress {
    description = "Allow HTTPS from ALB security group to instance"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    #    cidr_blocks = [aws_security_group.ec2_deployer_alb_sg.id]
    security_groups = [aws_security_group.ec2_deployer_alb_sg.id]

  }
  egress {
    description = "Allow HTTPS from instance to ALB SG"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    #    cidr_blocks = [aws_security_group.ec2_deployer_alb_sg.id]
    security_groups = [aws_security_group.ec2_deployer_alb_sg.id]
  }
  tags = local.common_tags
}
