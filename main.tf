terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_configuration" "example" {
  image_id           = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World!" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

#user_data_replace_on_change = true
    
}  
resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
    
    min_size             = 2
    max_size             = 10

    tag {
        key = "Name"
        value = "terraform-asg-example" 
        propagate_at_launch = true

}
}
resource "aws_security_group" "instance" {
    name  = "terraform_example_intance"

    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_lb" "example" {
    name               = "terraform-asg-example-lb"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids

}
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.example.arn
    port              = 80
    protocol          = "HTTP"
    
    default_action {
        type             = "fixed response"
        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code  = "404"
        }
    }
}
resource "aws_security_group" "alb" {
    name = "terraform_example_alb"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

}
    egress {
    from_port   = 0   
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}