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
