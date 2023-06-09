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

module "airflow" {
  source = "github.com/josersanvil/airflow-ecs-tf"

  airflow_fernet_key         = var.airflow_fernet_key
  airflow_web_admin_password = var.admin_password
  vpc_id                     = data.aws_vpc.default-vpc.id
}

