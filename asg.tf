#######################
# Auto Scaling Group
#######################
resource "aws_autoscaling_group" "ghost_ec2_pool" {
  name                = "ghost_ec2_pool"
  desired_capacity    = 2
  max_size           = 4
  min_size           = 1
  target_group_arns  = [aws_lb_target_group.ghost_ec2.arn]
  vpc_zone_identifier = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
    aws_subnet.public_c.id
  ]

  launch_template {
    id      = aws_launch_template.ghost.id
    version = "$Latest"
  }

  # Required for target group attachment
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value              = "ghost-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

#######################
# Optional: Scaling Policies
#######################
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "ghost_scale_up"
  scaling_adjustment     = 1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.ghost_ec2_pool.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "ghost_scale_down"
  scaling_adjustment     = -1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.ghost_ec2_pool.name
}

#######################
# Optional: CloudWatch Alarms for Auto Scaling
#######################
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "ghost-high-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "75"
  alarm_description  = "This metric monitors EC2 CPU utilization"
  alarm_actions      = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ghost_ec2_pool.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "ghost-low-cpu-usage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "30"
  alarm_description  = "This metric monitors EC2 CPU utilization"
  alarm_actions      = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ghost_ec2_pool.name
  }
}
