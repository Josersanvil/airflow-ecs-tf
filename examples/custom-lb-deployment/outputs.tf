output "airflow_web_server_hostname" {
  description = "Hostname of the Airflow Webserver"
  value       = module.airflow.airflow_web_server_hostname
}
