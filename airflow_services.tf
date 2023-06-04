
resource "aws_ecs_service" "airflow_webserver" {
  name                               = "airflow-webserver"
  cluster                            = aws_ecs_cluster.airflow_cluster.arn
  task_definition                    = aws_ecs_task_definition.airflow_webserver.arn
  deployment_maximum_percent         = "200"
  deployment_minimum_healthy_percent = "100"
  desired_count                      = "1"
  enable_ecs_managed_tags            = "true"
  enable_execute_command             = "false"
  health_check_grace_period_seconds  = "360"
  platform_version                   = "LATEST"
  propagate_tags                     = "TASK_DEFINITION"
  scheduling_strategy                = "REPLICA"
  force_new_deployment               = true

  depends_on = [
    time_sleep.wait_for_airflow_logs_efs_dns_propagation
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

  load_balancer {
    container_name   = "airflow-webserver"
    container_port   = "8080"
    target_group_arn = aws_lb_target_group.airflow_web_target.arn
  }

  network_configuration {
    assign_public_ip = "true"
    security_groups  = [aws_security_group.airflow_web_security_group.id]
    subnets          = local.airflow_vpc_subnets_ids
  }

  lifecycle {
    # Preserve the desired count when scaling the service
    ignore_changes = [desired_count]
  }
}

locals {
  airflow_control_plane_arns = {
    "airflow-scheduler" = aws_ecs_task_definition.airflow_scheduler.arn,
    "airflow-triggerer" = aws_ecs_task_definition.airflow_triggerer.arn,
    "airflow-worker"    = aws_ecs_task_definition.airflow_worker.arn,
  }
}

resource "aws_ecs_service" "airflow_control_plane" {
  for_each = toset(keys(local.airflow_control_plane_arns))

  name                               = each.key
  cluster                            = aws_ecs_cluster.airflow_cluster.arn
  task_definition                    = local.airflow_control_plane_arns[each.key]
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
    time_sleep.wait_for_airflow_logs_efs_dns_propagation,
    aws_ecs_service.airflow_redis
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
    security_groups  = [aws_security_group.airflow_web_security_group.id]
    subnets          = local.airflow_vpc_subnets_ids
  }

  lifecycle {
    # Preserve the desired count when scaling the service
    ignore_changes = [desired_count]
  }
}
