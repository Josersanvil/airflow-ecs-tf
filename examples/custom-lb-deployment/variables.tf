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

variable "load_balancer_name" {
  description = "Name of a custom load balancer used for exposing the Airflow Webserver. The load balancer must be in the same VPC as the Airflow resources"
  type        = string
}

variable "domain_name" {
  description = "Domain name (such as 'myorganization.com') to use for exposing the Airflow Webserver. The domain name must be managed by Route 53"
  type        = string
}
