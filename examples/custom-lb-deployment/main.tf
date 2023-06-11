# This example deploys the Web Server with a DNS record pointing to airflow.<domain name>.com
# and uses an ECR repository where a custom Airflow Docker image can be stored.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      environment           = "Development"
      application           = "Apache Airflow"
      managed_by            = "Terraform"
      airflow_deployment_id = module.airflow.airflow_deployment_id
    }
  }
}

data "aws_vpc" "default-vpc" {
  default = true
}

data "aws_lb" "load_balancer" {
  name = var.load_balancer_name
}

data "aws_lb_listener" "lb_https_listener" {
  load_balancer_arn = data.aws_lb.load_balancer.arn
  port              = 443
}

resource "aws_lb_listener_rule" "airflow_listener_rule" {
  listener_arn = data.aws_lb_listener.lb_https_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.airflow.airflow_web_target_group_arn
  }

  condition {
    host_header {
      values = ["airflow.${var.domain_name}"]
    }
  }
}

module "airflow" {
  source = "github.com/josersanvil/airflow-ecs-tf"

  airflow_fernet_key         = var.airflow_fernet_key
  airflow_web_admin_password = var.admin_password
  vpc_id                     = data.aws_vpc.default-vpc.id
  load_example_dags          = false
  custom_load_balancer_arn   = data.aws_lb.load_balancer.arn
  route_53_domain_name       = var.domain_name
  airflow_web_subdomain      = "airflow"
}
