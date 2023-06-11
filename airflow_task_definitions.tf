
resource "aws_ecs_task_definition" "airflow_webserver" {
  family                   = "airflow-webserver-${local.deployment_id}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"  # 0.5 vCPU
  memory                   = "1024" # 1 GB RAM
  execution_role_arn       = aws_iam_role.airflow_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.airflow_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "airflow-webserver"
      essential = true
      image     = "${var.airflow_image}:${var.airflow_image_tag}"
      command   = ["webserver"]
      portMappings = [
        {
          name          = "airflow-webserver"
          appProtocol   = "http"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_logs.name,
          awslogs-stream-prefix = "webserver",
          awslogs-region        = data.aws_region.current.name
        },
        secretOptions = []
      },
      mountPoints = [
        {
          containerPath = "/usr/local/airflow/logs"
          readOnly      = false
          sourceVolume  = "airflow-logs"
        }
      ],
      environment = local.environment_vars
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        retries     = 3
        startPeriod = 60
        timeout     = 5
      }
    }
  ])

  volume {
    name = "airflow-logs"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.airflow_logs.id
      root_directory = "/"
    }
  }

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_task_definition" "airflow_scheduler" {
  family                   = "airflow-scheduler-${local.deployment_id}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024" # 1 vCPU
  memory                   = "2048" # 2 GB RAM
  execution_role_arn       = aws_iam_role.airflow_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.airflow_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name         = "airflow-scheduler"
      essential    = true
      image        = "${var.airflow_image}:${var.airflow_image_tag}"
      command      = ["scheduler"]
      portMappings = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_logs.name,
          awslogs-stream-prefix = "scheduler",
          awslogs-region        = data.aws_region.current.name
        },
        secretOptions = []
      },
      mountPoints = [
        {
          containerPath = "/usr/local/airflow/logs"
          readOnly      = false
          sourceVolume  = "airflow-logs"
        }
      ],
      environment = local.environment_vars
      healthCheck = {
        command     = ["CMD-SHELL", "airflow jobs check --job-type SchedulerJob --hostname \"$${HOSTNAME}\""]
        interval    = 10
        retries     = 5
        startPeriod = 30
        timeout     = 10
      }
    }
  ])

  volume {
    name = "airflow-logs"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.airflow_logs.id
      root_directory = "/"
    }
  }

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}


resource "aws_ecs_task_definition" "airflow_worker" {
  family                   = "airflow-worker-${local.deployment_id}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024" # 1 vCPU
  memory                   = "2048" # 2 GB RAM
  execution_role_arn       = aws_iam_role.airflow_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.airflow_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name         = "airflow-worker"
      essential    = true
      image        = "${var.airflow_image}:${var.airflow_image_tag}"
      command      = ["celery", "worker"]
      portMappings = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_logs.name,
          awslogs-stream-prefix = "worker",
          awslogs-region        = data.aws_region.current.name
        },
        secretOptions = []
      },
      mountPoints = [
        {
          containerPath = "/usr/local/airflow/logs"
          readOnly      = false
          sourceVolume  = "airflow-logs"
        }
      ],
      environment = local.environment_vars
      healthCheck = {
        command     = ["CMD-SHELL", "celery --app airflow.executors.celery_executor.app inspect ping -d \"celery@$${HOSTNAME}\""]
        interval    = 10
        retries     = 5
        startPeriod = 30
        timeout     = 10
      }
    }
  ])

  volume {
    name = "airflow-logs"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.airflow_logs.id
      root_directory = "/"
    }
  }

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_task_definition" "airflow_triggerer" {
  family                   = "airflow-triggerer-${local.deployment_id}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"  # 0.5 vCPU
  memory                   = "1024" # 1 GB RAM
  execution_role_arn       = aws_iam_role.airflow_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.airflow_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name         = "airflow-triggerer"
      essential    = true
      image        = "${var.airflow_image}:${var.airflow_image_tag}"
      command      = ["triggerer"]
      portMappings = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_logs.name,
          awslogs-stream-prefix = "triggerer",
          awslogs-region        = data.aws_region.current.name
        },
        secretOptions = []
      },
      mountPoints = [
        {
          containerPath = "/usr/local/airflow/logs"
          readOnly      = false
          sourceVolume  = "airflow-logs"
        }
      ],
      environment = local.environment_vars
      healthCheck = {
        command     = ["CMD-SHELL", "airflow jobs check --job-type TriggererJob --hostname \"$${HOSTNAME}\""]
        interval    = 10
        retries     = 5
        startPeriod = 60
        timeout     = 10
      }
    }
  ])

  volume {
    name = "airflow-logs"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.airflow_logs.id
      root_directory = "/"
    }
  }

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_task_definition" "airflow_init" {
  family                   = "airflow-init-${local.deployment_id}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # .25 vCPU
  memory                   = "512" # 0.5 GB RAM
  execution_role_arn       = aws_iam_role.airflow_ecs_execution_role.arn
  task_role_arn            = aws_iam_role.airflow_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name         = "airflow-init"
      essential    = true
      image        = "${var.airflow_image}:${var.airflow_image_tag}"
      command      = ["db", "upgrade"]
      portMappings = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow_logs.name,
          awslogs-stream-prefix = "init",
          awslogs-region        = data.aws_region.current.name
        },
        secretOptions = []
      },
      environment = concat(
        local.environment_vars,
        [
          {
            "name"  = "_AIRFLOW_DB_UPGRADE"
            "value" = "true"
          },
          {
            "name"  = "_AIRFLOW_WWW_USER_CREATE"
            "value" = "true"
          },
          {
            "name"  = "_AIRFLOW_WWW_USER_USERNAME"
            "value" = "airflow"
          },
          {
            "name"  = "_AIRFLOW_WWW_USER_PASSWORD"
            "value" = var.airflow_web_admin_password
          }
        ]
      )
    }
  ])

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  provisioner "local-exec" {
    command = <<EOF
    aws ecs run-task \
      --cluster ${aws_ecs_cluster.airflow_cluster.name} \
      --task-definition ${aws_ecs_task_definition.airflow_init.arn} \
      --launch-type FARGATE \
      --network-configuration '{
        "awsvpcConfiguration": {
          "subnets": ${jsonencode(local.airflow_vpc_subnets_ids)},
          "securityGroups": ${jsonencode([data.aws_security_group.vpc_default_security_group.id])},
          "assignPublicIp": "ENABLED"
        }
      }' \
EOF
  }
}
