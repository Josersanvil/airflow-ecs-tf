variable "airflow_fernet_key" {
  description = "Fernet key used in Airflow to encrypt connections and variables"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Password for the Airflow Webserver admin user"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Route53 Domain name to use for accesing the Airflow Webserver"
  type        = string
}

variable "airflow_repo_name" {
  description = "Name of the ECR repository to use for storing the Airflow Docker image"
  type        = string
}
