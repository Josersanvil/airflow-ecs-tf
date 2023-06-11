# Custom Load Balancer Deployment

An Airflow deployment that uses a custom Application Load Balancer provided by the user in the default VPC.

A custom load balancer can be useful when you already have a load balancer in your VPC that you want to use for Airflow, or if you want to use other types of Load Balancer instead of an Application Load Balancer.

This example retrieves the load balancer by its name and creates a target rule that forwards traffic to the Airflow Webserver's ECS service when the path is `airflow.example.com`.

## Requirements

The following variables must be provided:

- `domain_name`: A domain name to use for accessing the Airflow Webserver. It must be a valid domain name and have a hosted zone in Route53.
- `load_balancer_name`: The name of the Load Balancer to use. It must be created outside of this module (like in the AWS Console for example or in another Terraform resource), be in the default VPC and have an HTTPS (port 443) listener with a valid certificate for the domain name provided.
