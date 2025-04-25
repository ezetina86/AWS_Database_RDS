#######################
# ECS Cluster
#######################
resource "aws_ecs_cluster" "ghost" {
  name = "ghost"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "ghost"
  }
}

#######################
# Task Definition
#######################
resource "aws_ecs_task_definition" "ghost" {
  family                   = "task_def_ghost"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 1024
  execution_role_arn      = aws_iam_role.ghost_ecs.arn
  task_role_arn           = aws_iam_role.ghost_ecs.arn

  # EFS Volume configuration
  volume {
    name = "ghost_volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.ghost_content.id
      root_directory = "/"
    }
  }

  container_definitions = jsonencode([
    {
      name      = "ghost_container"
      image     = "${aws_ecr_repository.ghost.repository_url}:4.12.1"
      essential = true
      environment = [
        { name = "database__client", value = "mysql" },
        { name = "database__connection__host", value = replace(aws_db_instance.ghost.endpoint, ":3306", "") },
        { name = "database__connection__user", value = var.db_username },
        { name = "database__connection__password", value = random_password.db_password.result },
        { name = "database__connection__database", value = "ghostdb" }
      ]
      mountPoints = [
        {
          containerPath = "/var/lib/ghost/content"
          sourceVolume  = "ghost_volume"
        }
      ]
      portMappings = [
        {
          containerPort = 2368
          hostPort      = 2368
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/ghost"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ghost"
        }
      }
    }
  ])

  tags = {
    Name = "task_def_ghost"
  }
}

#######################
# CloudWatch Log Group
#######################
resource "aws_cloudwatch_log_group" "ghost" {
  name              = "/ecs/ghost"
  retention_in_days = 30

  tags = {
    Name = "ghost-logs"
  }
}

#######################
# ECS Service
#######################
resource "aws_ecs_service" "ghost" {
  name            = "ghost"
  cluster         = aws_ecs_cluster.ghost.id
  task_definition = aws_ecs_task_definition.ghost.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
      aws_subnet.private_c.id
    ]
    security_groups  = [aws_security_group.fargate_pool.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ghost_fargate.arn
    container_name   = "ghost_container"
    container_port   = 2368
  }

  depends_on = [aws_lb_listener.ghost_http]

  tags = {
    Name = "ghost-service"
  }
}
