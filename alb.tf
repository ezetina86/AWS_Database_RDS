#######################
# ALB Target Groups
#######################
# Existing EC2 target group
resource "aws_lb_target_group" "ghost_ec2" {
  name        = "ghost-ec2"
  port        = 2368
  protocol    = "HTTP"
  vpc_id      = aws_vpc.cloudx.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval           = 30
    matcher            = "200"
    path               = "/ghost/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 10
    unhealthy_threshold = 5
  }

  tags = {
    Name = "ghost-ec2"
  }
}

# New Fargate target group
resource "aws_lb_target_group" "ghost_fargate" {
  name        = "ghost-fargate"
  port        = 2368
  protocol    = "HTTP"
  vpc_id      = aws_vpc.cloudx.id
  target_type = "ip"  # Important: Use "ip" for Fargate tasks

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval           = 30
    matcher            = "200"
    path               = "/ghost/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 10
    unhealthy_threshold = 5
  }

  tags = {
    Name = "ghost-fargate"
  }
}

#######################
# Application Load Balancer
#######################
resource "aws_lb" "ghost" {
  name               = "ghost-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
    aws_subnet.public_c.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "ghost-alb"
  }
}

#######################
# ALB Listener and Rules
#######################
# First, create listener with 100% traffic to Fargate
resource "aws_lb_listener" "ghost_http" {
  load_balancer_arn = aws_lb.ghost.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.ghost_fargate.arn
        weight = 100
      }
    }
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# Then, create a rule for 50/50 split (to be enabled after Fargate tasks are running)
resource "aws_lb_listener_rule" "ghost_split" {
  listener_arn = aws_lb_listener.ghost_http.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.ghost_ec2.arn
        weight = 50
      }
      target_group {
        arn    = aws_lb_target_group.ghost_fargate.arn
        weight = 50
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
