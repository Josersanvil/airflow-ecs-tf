data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "airflow_vpc" {
  id = var.vpc_id
}

data "aws_security_group" "vpc_default_security_group" {
  vpc_id = var.vpc_id
  name   = "default"
}

data "aws_subnets" "airflow_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "random_string" "deployment_id" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "random_password" "airflow_webserver_secret_key" {
  length  = 32
  special = false
}

locals {
  deployment_id        = random_string.deployment_id.result
  airflow_web_hostname = var.route_53_domain_name == null ? var.custom_load_balancer_arn == null ? aws_lb.airflow-alb[0].dns_name : data.aws_lb.custom_lb[0].dns_name : aws_route53_record.airflow-record[0].fqdn
  environment_vars = [
    {
      name  = "AIRFLOW__CORE__EXECUTOR"
      value = "CeleryExecutor"
    },
    {
      name  = "AIRFLOW__CORE__SQL_ALCHEMY_CONN"
      value = "postgresql+psycopg2://${urlencode(local.airflow_db_username)}:${urlencode(local.airflow_db_password)}@${aws_rds_cluster.airflow_db.endpoint}/${aws_rds_cluster.airflow_db.database_name}"
    },
    {
      name  = "AIRFLOW__CELERY__RESULT_BACKEND"
      value = "db+postgresql://${urlencode(local.airflow_db_username)}:${urlencode(local.airflow_db_password)}@${aws_rds_cluster.airflow_db.endpoint}/${aws_rds_cluster.airflow_db.database_name}"
    },
    {
      name  = "AIRFLOW__CELERY__BROKER_URL"
      value = "redis://redis.${aws_service_discovery_private_dns_namespace.airflow_namespace.name}:6379/0"
    },
    {
      name  = "AIRFLOW__CORE__FERNET_KEY"
      value = "${var.airflow_fernet_key}"
    },
    {
      name  = "AIRFLOW__WEBSERVER__SECRET_KEY"
      value = random_password.airflow_webserver_secret_key.result
    },
    {
      name  = "AIRFLOW__CORE__LOAD_EXAMPLES"
      value = var.load_example_dags ? "True" : "False"
    },
    {
      name  = "AIRFLOW__WEBSERVER__WARN_DEPLOYMENT_EXPOSURE"
      value = "False"
    },
    {
      name  = "AIRFLOW_VAR_AIRFLOW_DEPLOYMENT_ID"
      value = local.deployment_id
    },
    {
      name  = "AIRFLOW_VAR_AIRFLOW_DEPLOYMENT_ECS_CLUSTER_NAME"
      value = aws_ecs_cluster.airflow_cluster.name
    },
    {
      name  = "AIRFLOW_VAR_AIRFLOW_DEPLOYMENT_VPC_ID"
      value = var.vpc_id
    },
    {
      name  = "AIRFLOW_VAR_AIRFLOW_DEPLOYMENT_VPC_DEFAULT_SECURITY_GROUP_ID"
      value = data.aws_security_group.vpc_default_security_group.id
    },
    {
      name  = "AIRFLOW_VAR_AIRFLOW_DEPLOYMENT_VPC_SUBNETS"
      value = jsonencode(data.aws_subnets.airflow_vpc_subnets.ids)
    },
    {
      name  = "AIRFLOW_VAR_AIRFLOW_DEPLOYMENT_ECS_TASK_ROLE_ARN"
      value = aws_iam_role.airflow_ecs_task_role.arn
    },
    {
      name  = "AIRFLOW_VAR_AIRFLOW_DEPLOYMENT_CLOUDWATCH_LOG_GROUP_NAME"
      value = aws_cloudwatch_log_group.airflow_logs.name
    },
    {
      name  = "AIRFLOW_VAR_AIRFLOW_DEPLOYMENT_AWS_REGION"
      value = data.aws_region.current.name
    },
    {
      name  = "AIRFLOW_VAR_AIRFLOW_DEPLOYMENT_WEB_SERVER_HOSTNAME"
      value = local.airflow_web_hostname
    }
  ]
}

data "aws_secretsmanager_secret_version" "airflow_db_password" {
  secret_id = aws_rds_cluster.airflow_db.master_user_secret[0].secret_arn
}

# Credentials
locals {
  airflow_db_username = aws_rds_cluster.airflow_db.master_username
  airflow_db_password = jsondecode(data.aws_secretsmanager_secret_version.airflow_db_password.secret_string)["password"]
}

# Local variables for the VPC:
locals {
  airflow_vpc_id          = var.vpc_id
  airflow_vpc_subnets_ids = data.aws_subnets.airflow_vpc_subnets.ids
  airflow_vpc_cidr_block  = data.aws_vpc.airflow_vpc.cidr_block
}
