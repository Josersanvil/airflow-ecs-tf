# Variables can be set in a 'secrets.auto.tfvars' file
# or passed in via the command line with the -var flag

variable "airflow_fernet_key" {
  description = "Fernet key used in Airflow to encrypt connections and variables"
  type        = string
}

variable "admin_password" {
  description = "Password for the Airflow Webserver admin user"
  type        = string
}
