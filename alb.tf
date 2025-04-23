#######################
# ALB Target Group
#######################
resource "aws_lb_target_group" "ghost_ec2" {
  name        = "ghost-ec2"
  port        = 2368
  protocol    = "HTTP"
  vpc_id      = aws_vpc.cloudx.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "ghost-ec2"
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

  enable_deletion_protection = false # Set to true for production

  tags = {
    Name = "ghost-alb"
  }
}

#######################
# ALB Listener
#######################
resource "aws_lb_listener" "ghost_http" {
  load_balancer_arn = aws_lb.ghost.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ghost_ec2.arn

    # forward {
    #   target_group {
    #     arn    = aws_lb_target_group.ghost_ec2.arn
    #     weight = 100
    #   }
    # }
  }
}

resource "aws_lb_listener_rule" "ghost" {
  listener_arn = aws_lb_listener.ghost_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ghost_ec2.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
