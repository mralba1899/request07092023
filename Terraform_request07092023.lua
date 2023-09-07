provider "aws" {
  region = "eu-south-1" 
}

# Database MySQL
  resource "aws_db_instance" "mysql_db" {
  allocated_storage    = 30
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "ilmiodb"
  username             = "db_user"
  password             = "password01"
}

# Server EC2
resource "aws_instance"
 "apiserver" {
  ami           = "ami-xcentos" 
  instance_type = "t2.micro"
  key_name      = "key-vm"
}

# Application Load Balancer (ALB)
  resource "aws_lb" "alb-likefrontend" {
  name               = "example-api-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [subnet-xxxxxxxxxxxxx]
}

# Target Group for ALB
resource "aws_lb_target_group" "target_group" {
  name        = "target-group-api"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = vpc-xxxxxxxx
}

# Attach Target Group to ALB
resource "aws_lb_listener" "example_api_listener" {
  load_balancer_arn = aws_lb.alb-likefrontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type    = "text/plain"
      status_code     = "200"
      content         = "OK"
    }
  }
}

# Web Application Firewall (WAF)
resource "aws_waf_web_acl" "waf_api" {
  name        = "example-waf-acl"
  metric_name = "example-waf-metric"

  default_action {
    allow {}
  }
}

resource "aws_waf_rule" "waf_rule" {
  name        = "example-waf-rule"
  metric_name = "example-waf-metric"

  predicates {
    action = "ALLOW"
    type   = "IPMatch"
    data_id = aws_waf_ipset.ipallowed.id
  }
}

resource "aws_waf_ipset" "ipallowed" {
  name        = "example-waf-ipset"
  ip_set_descriptors = [
    {
      type = "IPV4"
      value = "193.43.15.6/32" 
    },
  ]
}

resource "aws_waf_web_acl_association" "example_waf_acl_association" {
  resource_arn = aws_lb.alb-likefrontend.arn
  web_acl_id   = aws_waf_web_acl.waf_api.id
}

# Autoscaling Group
resource "aws_launch_configuration" "example_launch_config" {
  name_prefix          = "autosc"
  image_id             = "ami-xcentos"
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.security_group.name]
  key_name             = "key-vm"
  user_data            = <<-EOF
    echo "This is your user data script"
  EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "security_group" {
  name_prefix = "sg-"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name_prefix = "scalingroup"
  launch_configuration = aws_launch_configuration.example_launch_config.name
  min_size     = 2
  max_size     = 5
  desired_capacity = 2
  vpc_zone_identifier = [subnet-xxxxxxxxxxxxx]
  target_group_arns   = [aws_lb_target_group.target_group.arn]
}

resource "aws_subnet" "example_subnet" {
  id = "ssubnet-xxxxxxxxxxxxx" 
}

resource "aws_vpc" "example_vpc" {
  id = "vpc-xxxxxxxx" 
}
