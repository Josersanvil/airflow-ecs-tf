output "airflow_web_server_hostname" {
  description = "Hostname of the Airflow Webserver"
  value       = module.airflow.airflow_web_server_hostname
}

output "airflow_ecr_repository_url" {
  description = "URL of the ECR repository containing the Airflow images"
  value       = data.aws_ecr_repository.airflow_repo.repository_url
}
