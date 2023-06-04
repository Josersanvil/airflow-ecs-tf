variable "airflow_fernet_key" {
  description = "Fernet key used in Airflow to encrypt connections and variables"
  type        = string
}

variable "airflow_web_admin_password" {
  description = "Password for the Airflow Webserver admin user"
  type        = string
}

variable "vpc_id" {
  description = "Id of the VPC where the Airflow resources will be deployed"
  type        = string
}

variable "execution_iam_policies_arns" {
  description = "List of IAM policies ARNs to attach to the ECS execution role, they can be used to grant permissions to the ECS services running the DAGs"
  type        = list(string)
  default     = []
}

variable "airflow_image" {
  description = "Airflow image to use for the deployment"
  type        = string
  default     = "apache/airflow"
}

variable "airflow_image_tag" {
  description = "Version Tag of the Airflow image to use for the deployment"
  type        = string
  default     = "latest"
}

variable "load_example_dags" {
  description = "Whether to load the example DAGs or not"
  type        = bool
  default     = true
}

variable "route_53_domain_name" {
  description = "Route 53 domain name (such as 'myorganization.com') to use for exposing the Airflow Webserver. If not provided, the Webserver will be exposed through the load balancer's DNS name"
  type        = string
  default     = null
}

variable "airflow_web_subomain" {
  description = "Subdomain to use for the Airflow Webserver (such as 'airflow' so is accessible at 'airflow.myorganization.com'). If not provided, the Webserver will be exposed through the Route 53 domain name"
  type        = string
  default     = ""
}

variable "airflow_db_acu_max_capacity" {
  description = "Maximum capacity of the Airflow database in Aurora Serverless ACUs"
  type        = number
  default     = 4
}

variable "airflow_db_acu_min_capacity" {
  description = "Minimum capacity of the Airflow database in Aurora Serverless ACUs"
  type        = number
  default     = 0.5
}

variable "airflow_webserver_scale_min_capacity" {
  description = "Minimun scaling capacity to have of Airflow Webserver ECS services"
  type        = number
  default     = 1
}

variable "airflow_webserver_scale_max_capacity" {
  description = "Maximum scaling capacity to have of Airflow Webserver ECS services"
  type        = number
  default     = 3
}

variable "airflow_scheduler_scale_min_capacity" {
  description = "Minimun scaling capacity to have of Airflow Scheduler ECS services"
  type        = number
  default     = 1
}

variable "airflow_scheduler_scale_max_capacity" {
  description = "Maximum scaling capacity to have of Airflow Scheduler ECS services"
  type        = number
  default     = 4
}
