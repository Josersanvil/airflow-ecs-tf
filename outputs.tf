output "rds_master_user_secret_arn" {
  description = "ARN of the secret containing the master user password for the Airflow database"
  value       = aws_rds_cluster.airflow_db.master_user_secret[0].secret_arn
}

output "airflow_deployment_id" {
  description = "Unique Id that identifies the Airflow deployment"
  value       = local.deployment_id
}

output "airflow_web_server_hostname" {
  description = "Hostname of the Airflow Webserver"
  value       = var.route_53_domain_name != null ? aws_route53_record.airflow-record[0].fqdn : aws_lb.airflow-alb.dns_name
}
