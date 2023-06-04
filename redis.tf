# Redis is used as a backend and broker for the Airflow Celery Executor.
# Redis is deployed as an ECS Service with an attached EFS volume for persistence.


resource "aws_ecs_task_definition" "airflow_redis" {
  family                   = "airflow-redis-${local.deployment_id}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024" # 1 vCPU
  memory                   = "2048" # 2 GB RAM
  execution_role_arn       = aws_iam_role.airflow_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.airflow_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "redis"
      essential = true
      image     = "redis:7.0.11-alpine"
      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
          protocol      = "tcp"
          name          = "redis-port"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_logs.name,
          awslogs-stream-prefix = "ecs",
          awslogs-region        = data.aws_region.current.name
        },
        secretOptions = []
      },
      mountPoints = [
        {
          containerPath = "/data"
          readOnly      = false
          sourceVolume  = "redis-data"
        }
      ],
      healthCheck = {
        command     = ["CMD-SHELL", "redis-cli ping || exit 1"]
        interval    = 10
        retries     = 5
        startPeriod = 60
        timeout     = 10
      }
    }
  ])

  volume {
    name = "redis-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.airflow_redis.id
      root_directory = "/"
    }
  }

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}


resource "aws_service_discovery_service" "airflow_redis_service" {
  name = "redis"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.airflow_namespace.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}


resource "aws_ecs_service" "airflow_redis" {
  name                               = "redis"
  cluster                            = aws_ecs_cluster.airflow_cluster.arn
  task_definition                    = aws_ecs_task_definition.airflow_redis.arn
  deployment_maximum_percent         = "200"
  deployment_minimum_healthy_percent = "100"
  desired_count                      = "1"
  enable_ecs_managed_tags            = "true"
  enable_execute_command             = "false"
  platform_version                   = "LATEST"
  propagate_tags                     = "TASK_DEFINITION"
  scheduling_strategy                = "REPLICA"
  force_new_deployment               = true

  depends_on = [
    time_sleep.wait_for_redis_efs_dns_propagation
  ]

  capacity_provider_strategy {
    base              = "0"
    capacity_provider = "FARGATE"
    weight            = "1"
  }

  deployment_circuit_breaker {
    enable   = "true"
    rollback = "true"
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    assign_public_ip = "true"
    security_groups  = [aws_security_group.airflow_redis_security_group.id]
    subnets          = local.airflow_vpc_subnets_ids
  }

  service_registries {
    registry_arn = aws_service_discovery_service.airflow_redis_service.arn
  }
}
