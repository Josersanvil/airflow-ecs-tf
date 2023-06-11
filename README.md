# Apache Airflow Infrastructure

This module contains the infrastructure as code for deploying [Apache Airflow](https://airflow.apache.org/) on AWS ECS using [Terraform](https://www.terraform.io/).

The deployment uses the Airflow [Celery Executor](https://airflow.apache.org/docs/stable/executor/celery.html) with [Redis](https://redis.io/) as the Celery message broker.

The resources created by this infrastructure are:

- An **ECS Cluster**
- **ECS Task Definitions** and **ECS Services** for:
  - **Airflow Webserver**, a Flask server that serves the Airflow UI.
  - **Airflow Scheduler**, a Daemon that schedules jobs.
  - **Airflow Worker**, a Celery worker that executes tasks.
  - **Airflow Triggerer**, a service that runs an Asyncio event loop that waits for tasks that use defferable operators to finish.
  - **Airflow Init**, a one-off task that initializes the Airflow metadata database.
  - **Redis**, used as the Celery message broker.
- An **RDS Postgres database** for the Airflow metadata database
- An **EFS Filesystem** for Container storage
- A **Application Load Balancer** for the Airflow Webserver (unless `custom_load_balancer_arns` is provided)
- **Auto Scaling policies** for the Airflow Webserver and Scheduler

The Worker does not have an Auto Scaling policy, consider using the [Amazon ECS Operators](https://airflow.apache.org/docs/apache-airflow-providers-amazon/stable/operators/ecs.html#) in your Airflow DAGs to avoid using too many worker resources.

A Route53 domain name can be provided to create a DNS record for the Airflow Webserver. The DNS record will be created pointing to the Application Load Balancer. This will also create a TLS certificate for the domain using [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/) and attach it to an Application Load Balancer HTTPS listener.

For more advanced usages take a look at the [examples folder](./examples/).

## Module Usage

### Prerequisites

Set the [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) in your Terraform code in a `providers` block and using the `required_providers` parameter of the [terraform configuration block](https://www.terraform.io/docs/language/settings/index.html#required_providers). Example:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"

  # Some default tags for the resources created by the module are also useful
  default_tags {
    tags = {
      managedBy   = "Terraform"
      application = "Apache Airflow"
    }
  }
}
```

### Deploy the Infrastructure

The following parameters are required to deploy the module:

- `vpc_id`: The ID of the VPC where the Airflow infrastructure will be deployed. The VPC must have at least 2 private subnets and 2 public subnets (Preferably in different AZs).
- `airflow_fernet_key`: [Fernet key](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/security/secrets/fernet.html#generating-fernet-key) used in Airflow to encrypt connections and variables. To generate a key you can use the following command: `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"` (Requires `pip install cryptography`).
- `airflow_admin_password`: Password for the `airflow` admin user used to access the Airflow Web UI.

Check the [variables.tf](./variables.tf) file for more information about the rest of parameters that can be configured for the module.

Import the module in your Terraform code:

```hcl
module "airflow" {
  source = "github.com/josersanvil/airflow-ecs-tf"

  # ... see variables.tf for all parameters
  vpc_id                     = var.vpc_id
  airflow_fernet_key         = var.airflow_fernet_key
  airflow_web_admin_password = var.admin_password
}
```

Then run `terraform init` and `terraform apply` to deploy the infrastructure.

The module will output the following values:

- `airflow_web_server_hostname`: The hostname of the Airflow Webserver. If a Route53 domain name is provided, this will be the domain name. Otherwise, it will be the DNS name of the Application Load Balancer.
- `airflow_deployment_id`: An unique ID of 6 characters used on the deployment of the infrastructure.
- `rds_master_user_secret_arn`: The ARN of the AWS Secrets Manager secret that contains the master user password for the RDS database.

You can use the `airflow_web_server_hostname` output to access the Airflow Web UI, the admin username is `airflow` and the password is the one provided in the `airflow_web_admin_password` parameter.

## Customize the Airflow Docker Image

By default the module uses the `latest` tag of the [apache/airflow](https://hub.docker.com/r/apache/airflow) Docker image. You can customize the image by setting the parameters `airflow_image` and `airflow_image_tag` of the module.

For example, you can use your own custom Airflow image hosted in ECR:

```terraform
data aws_vpc "default_vpc" {
  default = true
}

data "aws_ecr_repository" "my_airflow_images" {
  name = "my-airflow-images"
}

module "airflow" {
  source = "modules/airflow"

  airflow_fernet_key         = var.airflow_fernet_key
  airflow_admin_password     = var.airflow_admin_password
  vpc_id                     = data.aws_vpc.default_vpc.id
  airflow_image              = data.aws_ecr_repository.my_airflow_images.repository_url
  airflow_image_tag          = "latest"
}
```

## Airflow Variables

Some environment variables are set in the containers that run the Airflow Services which can be used in your DAGs as [Airflow Variables](https://airflow.apache.org/docs/stable/concepts.html#variables) to run tasks using the [EcsRunTaskOperator](https://airflow.apache.org/docs/apache-airflow-providers-amazon/stable/operators/ecs.html#run-a-task-definition).

| Variable | Description | Example |
| --- | --- | --- |
| `AIRFLOW_DEPLOYMENT_ID` | An unique ID of 6 characters used on the deployment of the infrastructure. | `pz3us1` |
| `AIRFLOW_DEPLOYMENT_ECS_CLUSTER_NAME` | The name of the ECS cluster created by the deployment of the module. | `Airflow-pz3us1` |
| `AIRFLOW_DEPLOYMENT_VPC_ID` | The ID of the VPC where the Airflow infrastructure is deployed. | `vpc-1234567890` |
| `AIRFLOW_DEPLOYMENT_VPC_DEFAULT_SECURITY_GROUP_ID` | The ID of the default security group of the VPC where the Airflow infrastructure is deployed. | `sg-1234567890` |
| `AIRFLOW_DEPLOYMENT_VPC_SUBNETS` | A json-encoded list of the IDs of the subnets of the VPC where the Airflow infrastructure is deployed. | `["subnet-1234567890", "subnet-1234567891"]` |
| `AIRFLOW_DEPLOYMENT_ECS_EXECUTION_ROLE_ARN` | The ARN of the IAM role used to execute the ECS tasks. | `arn:aws:iam::1234567890:role/Airflow-pz3us1-EcsExecutionRole` |
| `AIRFLOW_DEPLOYMENT_CLOUDWATCH_LOG_GROUP_NAME` | The name of the CloudWatch log group created by the deployment of the module. | `/ecs/Airflow-pz3us1` |
| `AIRFLOW_DEPLOYMENT_AWS_REGION` | The AWS region where the Airflow infrastructure is deployed. | `eu-west-1` |
| `AIRFLOW_DEPLOYMENT_WEB_SERVER_HOSTNAME` | The hostname of the Airflow Webserver. | `airflow.mydomain.com` or `airflow-alb-pz3us1-1234567890.eu-west-1.elb.amazonaws.com` when not using a custom domain. |
