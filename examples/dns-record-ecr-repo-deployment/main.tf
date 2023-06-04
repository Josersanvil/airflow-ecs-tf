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

data "aws_route53_zone" "my_domain" {
  name = var.domain_name
}

data "aws_ecr_repository" "airflow_repo" {
  name = var.airflow_repo_name
}

module "airflow" {
  source = "github.com/josersanvil/airflow-ecs-tf"

  airflow_fernet_key         = var.airflow_fernet_key
  airflow_web_admin_password = var.admin_password
  vpc_id                     = data.aws_vpc.default-vpc.id
  airflow_image              = data.aws_ecr_repository.airflow_repo.repository_url
  airflow_image_tag          = "development"
  airflow_web_subomain       = "airflow"
  load_example_dags          = false
  route_53_domain_name       = data.aws_route53_zone.my_domain.name
}
