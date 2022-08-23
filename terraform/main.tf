####################################################################
# ECS
####################################################################

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${local.env}-${local.project}-ecs-cluster"
}

resource "aws_cloudwatch_log_group" "log_group" {
  retention_in_days = 7
  name              = "${local.env}/${local.project}/ecs_task"
}

# Define container definition
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "techChallengeApp-task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "techChallengeApp-task",
      "image": "servian/techchallengeapp:latest",
      "essential": true,
      "logConfiguration": {
       "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${aws_cloudwatch_log_group.log_group.name}",
         "awslogs-region": "ap-southeast-2",
         "awslogs-stream-prefix": "ecs_task"
       }
     },
      "environment": [
        {
          "name": "VTT_DBHOST",
          "value": "${aws_db_instance.rds.endpoint}"
        },
        {
          "name": "VTT_DBPORT",
          "value": "${aws_db_instance.rds.port}"
        },
        {
          "name": "VTT_DBUSER",
          "value": "${aws_db_instance.rds.username}"
        },
        {
          "name": "VTT_DBPASSWORD",
          "value": "${data.aws_secretsmanager_secret_version.db_secret.secret_string}"
        },
        {
          "name": "VTT_DBBNAME",
          "value": "${aws_db_instance.rds.name}"
        },
        {
          "name": "VTT_LISTENHOST",
          "value": "0.0.0.0"
        },
        {
          "name": "VTT_LISTENPORT",
          "value": "${var.app_port}"
        }
    ],
      "portMappings": [
        {
          "containerPort": ${var.app_port}
        }
      ],
      "memory": 512,
      "cpu": 256,
      "command" : ["serve"]
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn
}

# Define the webserver service
resource "aws_ecs_service" "ecs_service" {
  depends_on = [
    aws_iam_role.ecsTaskExecutionRole,
    aws_secretsmanager_secret_version.secret_password
  ]
  name            = "${local.env}-${local.project}-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = aws_ecs_task_definition.ecs_task.family
    container_port   = var.app_port
  }

  network_configuration {
    subnets         = [aws_subnet.private_subnet_2a.id, aws_subnet.private_subnet_2b.id, aws_subnet.private_subnet_2c.id]
    security_groups = [aws_security_group.ecs_security_group.id]
  }
}

#--------ECS Autoscaling

# ECS autoscaling target to set scaling objectives 
resource "aws_appautoscaling_target" "appautoscaling_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# policy to auto scale ecs cluster based on cpu utlization
resource "aws_appautoscaling_policy" "asgp_memory" {
  name               = "${local.env}-${local.project}-asgp_memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appautoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.appautoscaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

# policy to auto scale ecs cluster based on cpu utlization
resource "aws_appautoscaling_policy" "asgp_cpu" {
  name               = "${local.env}-${local.project}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appautoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.appautoscaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}

####################################################################
# ELB 
####################################################################

resource "aws_alb" "application_load_balancer" {
  name               = "${local.env}-${local.project}-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_2a.id, aws_subnet.public_subnet_2b.id, aws_subnet.public_subnet_2c.id]
  security_groups    = [aws_security_group.load_balancer_security_group.id]
}

# ELB target group
resource "aws_lb_target_group" "target_group" {
  name        = "${local.env}-${local.project}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main_vpc.id
  health_check {
    path = "/healthcheck/"
    port = var.app_port
  }
}

# ELB http listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

####################################################################
# RDS
####################################################################

# Postgres DB
resource "aws_db_instance" "rds" {
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "postgres"
  engine_version    = "10.18"
  instance_class    = "db.t2.micro"
  db_name           = "postgresdb"
  username          = "${var.dbuser}"
  password               = random_password.password.result # random passpord
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  skip_final_snapshot    = true
}




