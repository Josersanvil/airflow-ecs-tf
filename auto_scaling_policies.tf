# === Autoscaling policies for Airflow Webserver ====

resource "aws_appautoscaling_target" "airflow_webserver_target" {
  min_capacity       = var.airflow_webserver_scale_min_capacity
  max_capacity       = var.airflow_webserver_scale_max_capacity
  resource_id        = "service/${aws_ecs_cluster.airflow_cluster.name}/${aws_ecs_service.airflow_webserver.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_airflow_webserver_target_cpu" {
  name               = "airflow-webserver-cpu-autoscale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.airflow_webserver_target.resource_id
  scalable_dimension = aws_appautoscaling_target.airflow_webserver_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.airflow_webserver_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }

  depends_on = [aws_appautoscaling_target.airflow_webserver_target]
}

resource "aws_appautoscaling_policy" "ecs_airflow_webserver_target_memory" {
  name               = "airflow-webserver-memory-autoscale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.airflow_webserver_target.resource_id
  scalable_dimension = aws_appautoscaling_target.airflow_webserver_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.airflow_webserver_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 70
  }

  depends_on = [aws_appautoscaling_target.airflow_webserver_target]
}

# === Autoscaling policies for Airflow Scheduler ====

resource "aws_appautoscaling_target" "airflow_scheduler_target" {
  min_capacity       = var.airflow_scheduler_scale_min_capacity
  max_capacity       = var.airflow_scheduler_scale_max_capacity
  resource_id        = "service/${aws_ecs_cluster.airflow_cluster.name}/${aws_ecs_service.airflow_control_plane["airflow-scheduler"].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_airflow_scheduler_target_cpu" {
  name               = "airflow-scheduler-cpu-autoscale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.airflow_scheduler_target.resource_id
  scalable_dimension = aws_appautoscaling_target.airflow_scheduler_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.airflow_scheduler_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }

  depends_on = [aws_appautoscaling_target.airflow_scheduler_target]
}

resource "aws_appautoscaling_policy" "ecs_airflow_scheduler_target_memory" {
  name               = "airflow-scheduler-memory-autoscale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.airflow_scheduler_target.resource_id
  scalable_dimension = aws_appautoscaling_target.airflow_scheduler_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.airflow_scheduler_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 70
  }

  depends_on = [aws_appautoscaling_target.airflow_scheduler_target]
}
