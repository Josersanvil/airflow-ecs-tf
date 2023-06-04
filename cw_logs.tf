resource "aws_cloudwatch_log_group" "airflow_logs" {
  name              = "/airflow/${local.deployment_id}"
  retention_in_days = 7
}
